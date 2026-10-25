import base64
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders

import httpx

from worker.modules.registry import register_module
from worker.utils.decorators import async_retry
from worker.utils.google_auth import get_google_access_token

logger = logging.getLogger(__name__)

GMAIL_API_BASE = "https://gmail.googleapis.com/gmail/v1/users/me"


def _raise_if_forbidden(response: httpx.Response):
    if response.status_code == 403:
        raise ValueError(
            "Permissão negada pelo Gmail. "
            "Você precisa reconectar sua conta do Google no app "
            "(Configurações > Integrações > Google Workspace) "
            "e autorizar o acesso de envio de e-mails."
        )
    response.raise_for_status()


def _build_rfc2822_message(
    to: str, subject: str, body: str, cc: str = None, attachments=()
) -> str:
    if any(
        not isinstance(value, str) or "\r" in value or "\n" in value
        for value in (to, subject)
    ):
        raise ValueError("Cabeçalho de e-mail inválido")
    if cc is not None and (not isinstance(cc, str) or "\r" in cc or "\n" in cc):
        raise ValueError("Cc inválido")
    if not isinstance(body, str):
        raise ValueError("Corpo de e-mail inválido")
    msg = MIMEMultipart() if cc or attachments else MIMEText(body, "plain", "utf-8")
    msg["To"] = to
    msg["Subject"] = subject
    if cc:
        msg["Cc"] = cc
    if cc or attachments:
        msg.attach(MIMEText(body, "plain", "utf-8"))
    for filename, content_type, content in attachments:
        main_type, sub_type = content_type.split("/", 1)
        part = MIMEBase(main_type, sub_type)
        part.set_payload(content)
        encoders.encode_base64(part)
        part.add_header("Content-Disposition", "attachment", filename=filename)
        msg.attach(part)
    return base64.urlsafe_b64encode(msg.as_bytes()).decode()


def _load_owned_attachments(user_id: str, attachment_ids) -> list:
    if (
        not isinstance(attachment_ids, list)
        or len(attachment_ids) > 5
        or any(not isinstance(item, str) for item in attachment_ids)
        or len(set(attachment_ids)) != len(attachment_ids)
    ):
        raise ValueError("Informe até cinco IDs de anexos distintos")
    if not attachment_ids:
        return []
    from worker.repositorio_dados import obter_app
    from models.attachment import Attachment
    from services.storage.attachment_service import AttachmentService

    result = []
    total = 0
    with obter_app().app_context():
        for attachment_id in attachment_ids:
            attachment = Attachment.query.filter_by(
                id=attachment_id, user_id=user_id
            ).first()
            if not attachment:
                raise ValueError("Anexo não encontrado para este usuário")
            total += attachment.size_bytes
            if total > 15 * 1024 * 1024:
                raise ValueError("Anexos excedem 15 MB")
            result.append(
                (
                    attachment.original_name,
                    attachment.content_type,
                    AttachmentService._baixar_storage(attachment.storage_path),
                )
            )
    return result


@register_module("gmail.send_email")
@async_retry(retries=3, delay=1.0, backoff=2.0)
async def gmail_send_email(params: dict) -> dict:
    user_id = params.get("user_id")
    to = params.get("to")
    subject = params.get("subject")
    body = params.get("body")
    cc = params.get("cc")
    attachment_ids = params.get("attachment_ids", [])

    required = {
        "a conta conectada": user_id,
        "o destinatário": to,
        "o assunto": subject,
        "a mensagem": body,
    }
    missing = [label for label, value in required.items() if not value]
    if missing:
        raise ValueError(
            "Não foi possível enviar o e-mail porque faltou " + ", ".join(missing) + "."
        )

    token = get_google_access_token(user_id, "google_gmail")
    attachments = _load_owned_attachments(user_id, attachment_ids)
    raw_message = _build_rfc2822_message(to, subject, body, cc, attachments)

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{GMAIL_API_BASE}/messages/send",
            headers={"Authorization": f"Bearer {token}"},
            json={"raw": raw_message},
            timeout=30.0,
        )
        _raise_if_forbidden(response)
        data = response.json()

    logger.info(f"✅ E-mail enviado para {to}, messageId: {data.get('id')}")
    return {
        "message_id": data.get("id"),
        "thread_id": data.get("threadId"),
    }


@register_module("gmail.create_draft")
@async_retry(retries=3, delay=1.0, backoff=2.0)
async def gmail_create_draft(params: dict) -> dict:
    user_id = params.get("user_id")
    to = params.get("to")
    subject = params.get("subject")
    body = params.get("body")

    required = {
        "a conta conectada": user_id,
        "o destinatário": to,
        "o assunto": subject,
        "a mensagem": body,
    }
    missing = [label for label, value in required.items() if not value]
    if missing:
        raise ValueError(
            "Não foi possível criar o rascunho porque faltou "
            + ", ".join(missing)
            + "."
        )

    token = get_google_access_token(user_id, "google_gmail")
    raw_message = _build_rfc2822_message(to, subject, body)

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{GMAIL_API_BASE}/drafts",
            headers={"Authorization": f"Bearer {token}"},
            json={"message": {"raw": raw_message}},
            timeout=30.0,
        )
        _raise_if_forbidden(response)
        data = response.json()

    logger.info(f"✅ Rascunho criado para {to}, draftId: {data.get('id')}")
    return {
        "draft_id": data.get("id"),
        "message_id": data.get("message", {}).get("id"),
    }


@register_module("gmail.get_unread_emails")
@async_retry(retries=3, delay=1.0, backoff=2.0)
async def gmail_get_unread_emails(params: dict) -> dict:
    user_id = params.get("user_id")
    max_results = params.get("max_results", 10)

    if not user_id:
        raise ValueError("Parâmetro obrigatório: user_id")

    token = get_google_access_token(user_id, "google_gmail")

    async with httpx.AsyncClient() as client:
        list_resp = await client.get(
            f"{GMAIL_API_BASE}/messages",
            headers={"Authorization": f"Bearer {token}"},
            params={"q": "is:unread", "maxResults": max_results},
            timeout=30.0,
        )
        list_resp.raise_for_status()
        list_data = list_resp.json()

    messages_meta = list_data.get("messages", [])
    if not messages_meta:
        return {"emails": []}

    emails = []
    async with httpx.AsyncClient() as client:
        for msg_meta in messages_meta:
            msg_resp = await client.get(
                f"{GMAIL_API_BASE}/messages/{msg_meta['id']}",
                headers={"Authorization": f"Bearer {token}"},
                timeout=30.0,
            )
            msg_resp.raise_for_status()
            msg_data = msg_resp.json()

            headers = {
                h["name"]: h["value"]
                for h in msg_data.get("payload", {}).get("headers", [])
            }

            payload = msg_data.get("payload", {})
            snippet = msg_data.get("snippet", "")
            body_data = ""
            if payload.get("body", {}).get("data"):
                body_data = base64.urlsafe_b64decode(payload["body"]["data"]).decode(
                    "utf-8", errors="ignore"
                )

            emails.append(
                {
                    "id": msg_data["id"],
                    "thread_id": msg_data.get("threadId"),
                    "from": headers.get("From", ""),
                    "to": headers.get("To", ""),
                    "subject": headers.get("Subject", ""),
                    "date": headers.get("Date", ""),
                    "snippet": snippet,
                    "body_preview": body_data[:500],
                }
            )

    logger.info(f"📬 {len(emails)} e-mails não lidos encontrados")
    return {"emails": emails}
