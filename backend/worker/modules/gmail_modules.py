import base64
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

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


def _build_rfc2822_message(to: str, subject: str, body: str, cc: str = None) -> str:
    msg = MIMEMultipart() if cc else MIMEText(body, "plain")
    msg["To"] = to
    msg["Subject"] = subject
    if cc:
        msg["Cc"] = cc
        msg.attach(MIMEText(body, "plain"))
    return base64.urlsafe_b64encode(msg.as_bytes()).decode()


@register_module("gmail.send_email")
@async_retry(retries=3, delay=1.0, backoff=2.0)
async def gmail_send_email(params: dict) -> dict:
    user_id = params.get("user_id")
    to = params.get("to")
    subject = params.get("subject")
    body = params.get("body")
    cc = params.get("cc")

    if not all([user_id, to, subject, body]):
        raise ValueError("Parâmetros obrigatórios: user_id, to, subject, body")

    token = get_google_access_token(user_id, "google_gmail")
    raw_message = _build_rfc2822_message(to, subject, body, cc)

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

    if not all([user_id, to, subject, body]):
        raise ValueError("Parâmetros obrigatórios: user_id, to, subject, body")

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

            headers = {h["name"]: h["value"] for h in msg_data.get("payload", {}).get("headers", [])}

            payload = msg_data.get("payload", {})
            snippet = msg_data.get("snippet", "")
            body_data = ""
            if payload.get("body", {}).get("data"):
                body_data = base64.urlsafe_b64decode(payload["body"]["data"]).decode("utf-8", errors="ignore")

            emails.append({
                "id": msg_data["id"],
                "thread_id": msg_data.get("threadId"),
                "from": headers.get("From", ""),
                "to": headers.get("To", ""),
                "subject": headers.get("Subject", ""),
                "date": headers.get("Date", ""),
                "snippet": snippet,
                "body_preview": body_data[:500],
            })

    logger.info(f"📬 {len(emails)} e-mails não lidos encontrados")
    return {"emails": emails}
