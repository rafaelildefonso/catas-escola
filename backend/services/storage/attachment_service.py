from io import BytesIO
import logging
from pathlib import PurePosixPath
import uuid
import zipfile
from xml.etree import ElementTree

import httpx
from werkzeug.utils import secure_filename

from core.config import settings
from extensions import db
from models.attachment import Attachment
from models.profile import Profile
from services.profile.verificar_quota_service import CONFIG_QUOTA

logger = logging.getLogger(__name__)

_BUCKET = "attachments"
_SIGNED_URL_TTL_SECONDS = 3600
_MAX_DOCX_UNCOMPRESSED_BYTES = 40 * 1024 * 1024
_MIME_TYPES = {
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "png": "image/png",
    "gif": "image/gif",
    "webp": "image/webp",
    "pdf": "application/pdf",
    "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
}
_MAGIC_BYTES = {
    "jpg": lambda data: data.startswith(b"\xff\xd8\xff"),
    "jpeg": lambda data: data.startswith(b"\xff\xd8\xff"),
    "png": lambda data: data.startswith(b"\x89PNG\r\n\x1a\n"),
    "gif": lambda data: data.startswith((b"GIF87a", b"GIF89a")),
    "webp": lambda data: len(data) >= 12 and data[:4] == b"RIFF" and data[8:12] == b"WEBP",
    "pdf": lambda data: data.startswith(b"%PDF-"),
    "docx": lambda data: data.startswith(b"PK\x03\x04"),
}


class AttachmentError(Exception):
    def __init__(self, message: str, status_code: int = 400):
        super().__init__(message)
        self.status_code = status_code


class AttachmentService:
    @staticmethod
    def upload(user_id: str, nome: str, content_type: str, conteudo: bytes):
        arquivo_limpo = secure_filename(nome)
        extensao = PurePosixPath(arquivo_limpo).suffix.lower().lstrip(".")
        if extensao not in _MIME_TYPES:
            raise AttachmentError("Tipo de arquivo não permitido. Envie imagens, PDF ou DOCX.")
        if not conteudo:
            raise AttachmentError("O arquivo está vazio.")
        if len(conteudo) > settings.ATTACHMENTS_MAX_SIZE_BYTES:
            raise AttachmentError("O arquivo excede o limite de 10 MB.", 413)
        if not _MAGIC_BYTES[extensao](conteudo):
            raise AttachmentError("O conteúdo do arquivo não corresponde à extensão informada.")
        esperado = _MIME_TYPES[extensao]
        if content_type and content_type not in {"application/octet-stream", esperado}:
            raise AttachmentError("O MIME informado não corresponde ao tipo do arquivo.")
        if extensao == "docx":
            AttachmentService._validar_docx(conteudo)
        profile = Profile.buscar_por_id(user_id)
        if not profile:
            raise AttachmentError("Perfil não encontrado.", 404)
        tier = (profile.subscription_tier or "basic").lower()
        limite_anexos = CONFIG_QUOTA.get(tier, CONFIG_QUOTA["basic"])["attachment_limit"]
        if Attachment.query.filter_by(user_id=user_id).count() >= limite_anexos:
            raise AttachmentError("Você atingiu o limite de arquivos do seu plano.", 403)

        attachment_id = str(uuid.uuid4())
        storage_path = f"{user_id}/{attachment_id}.{extensao}"
        AttachmentService._upload_storage(storage_path, esperado, conteudo)
        attachment = Attachment(
            id=attachment_id,
            user_id=user_id,
            original_name=arquivo_limpo[:255],
            storage_path=storage_path,
            content_type=esperado,
            size_bytes=len(conteudo),
        )
        try:
            signed_url = AttachmentService._url_assinada(storage_path)
            db.session.add(attachment)
            db.session.commit()
        except Exception:
            db.session.rollback()
            try:
                AttachmentService._remover_storage(storage_path)
            except AttachmentError:
                logger.exception("Falha ao limpar upload após erro.")
            raise

        return attachment.to_dict(signed_url)

    @staticmethod
    def listar(user_id: str):
        attachments = (
            Attachment.query.filter_by(user_id=user_id)
            .order_by(Attachment.created_at.desc())
            .limit(1000)
            .all()
        )
        return [
            attachment.to_dict(AttachmentService._url_assinada(attachment.storage_path))
            for attachment in attachments
        ]

    @staticmethod
    def excluir(user_id: str, attachment_id: str):
        attachment = Attachment.query.filter_by(id=attachment_id, user_id=user_id).first()
        if not attachment:
            raise AttachmentError("Arquivo não encontrado.", 404)
        AttachmentService._remover_storage(attachment.storage_path)
        db.session.delete(attachment)
        db.session.commit()

    @staticmethod
    def visualizar_docx(user_id: str, attachment_id: str):
        attachment = Attachment.query.filter_by(id=attachment_id, user_id=user_id).first()
        if not attachment:
            raise AttachmentError("Arquivo não encontrado.", 404)
        if attachment.content_type != _MIME_TYPES["docx"]:
            raise AttachmentError("A pré-visualização de texto está disponível somente para DOCX.")
        conteudo = AttachmentService._baixar_storage(attachment.storage_path)
        try:
            with zipfile.ZipFile(BytesIO(conteudo)) as arquivo:
                documento = ElementTree.fromstring(arquivo.read("word/document.xml"))
        except (KeyError, zipfile.BadZipFile, ElementTree.ParseError) as erro:
            raise AttachmentError("Não foi possível ler o documento DOCX.") from erro

        ns = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
        paragrafos = []
        for paragrafo in documento.findall(".//w:p", ns):
            texto = "".join(no.text or "" for no in paragrafo.findall(".//w:t", ns))
            if texto.strip():
                paragrafos.append(texto)
        return {"id": attachment.id, "name": attachment.original_name, "text": "\n\n".join(paragrafos)}

    @staticmethod
    def _validar_docx(conteudo: bytes):
        try:
            with zipfile.ZipFile(BytesIO(conteudo)) as arquivo:
                total = sum(item.file_size for item in arquivo.infolist())
                if total > _MAX_DOCX_UNCOMPRESSED_BYTES:
                    raise AttachmentError("O documento DOCX é muito grande para pré-visualização.")
                if "word/document.xml" not in arquivo.namelist():
                    raise AttachmentError("O arquivo não contém um documento DOCX válido.")
        except zipfile.BadZipFile as erro:
            raise AttachmentError("O arquivo DOCX é inválido.") from erro

    @staticmethod
    def _base_storage_url():
        if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
            raise AttachmentError("O armazenamento de anexos não está configurado.", 503)
        return f"{settings.SUPABASE_URL}/storage/v1"

    @staticmethod
    def _headers(content_type=None):
        headers = {
            "apikey": settings.SUPABASE_SERVICE_ROLE_KEY,
            "Authorization": f"Bearer {settings.SUPABASE_SERVICE_ROLE_KEY}",
        }
        if content_type:
            headers["Content-Type"] = content_type
        return headers

    @staticmethod
    def _garantir_bucket():
        base_url = AttachmentService._base_storage_url()
        try:
            with httpx.Client(timeout=20) as client:
                response = client.get(
                    f"{base_url}/bucket/{_BUCKET}",
                    headers=AttachmentService._headers(),
                )
                if response.status_code == 200:
                    return
                if response.status_code != 404:
                    AttachmentService._falha_provedor("verificar o bucket", response)
                response = client.post(
                    f"{base_url}/bucket",
                    headers=AttachmentService._headers("application/json"),
                    json={
                        "id": _BUCKET,
                        "name": _BUCKET,
                        "public": False,
                        "file_size_limit": settings.ATTACHMENTS_MAX_SIZE_BYTES,
                        "allowed_mime_types": list(_MIME_TYPES.values()),
                    },
                )
                if response.status_code in {200, 201, 409}:
                    return
                AttachmentService._falha_provedor("criar o bucket", response)
        except httpx.HTTPError as erro:
            logger.exception("Falha de conexão com o Supabase Storage ao verificar bucket.")
            raise AttachmentError("Não foi possível acessar o armazenamento de arquivos.", 502) from erro

    @staticmethod
    def _upload_storage(path: str, content_type: str, conteudo: bytes):
        AttachmentService._garantir_bucket()
        encoded_path = path.replace(" ", "%20")
        try:
            with httpx.Client(timeout=30) as client:
                response = client.post(
                    f"{AttachmentService._base_storage_url()}/object/{_BUCKET}/{encoded_path}",
                    headers={
                        **AttachmentService._headers(content_type),
                        "x-upsert": "false",
                    },
                    content=conteudo,
                )
            if response.status_code not in {200, 201}:
                AttachmentService._falha_provedor("enviar o arquivo", response)
        except httpx.HTTPError as erro:
            logger.exception("Falha de conexão com o Supabase Storage durante upload.")
            raise AttachmentError("Não foi possível enviar o arquivo ao armazenamento.", 502) from erro

    @staticmethod
    def _url_assinada(path: str):
        AttachmentService._garantir_bucket()
        encoded_path = path.replace(" ", "%20")
        try:
            with httpx.Client(timeout=20) as client:
                response = client.post(
                    f"{AttachmentService._base_storage_url()}/object/sign/{_BUCKET}/{encoded_path}",
                    headers=AttachmentService._headers("application/json"),
                    json={"expiresIn": _SIGNED_URL_TTL_SECONDS},
                )
            if response.status_code != 200:
                AttachmentService._falha_provedor("gerar link de acesso", response)
        except httpx.HTTPError as erro:
            logger.exception("Falha de conexão com o Supabase Storage ao gerar link.")
            raise AttachmentError("Não foi possível gerar o link do arquivo.", 502) from erro

        try:
            signed_url = response.json().get("signedURL")
        except ValueError as erro:
            raise AttachmentError("O armazenamento retornou uma resposta inválida.", 502) from erro
        if not signed_url:
            raise AttachmentError("O armazenamento não retornou um link para o arquivo.", 502)
        if signed_url.startswith("http"):
            return signed_url
        return f"{settings.SUPABASE_URL}/storage/v1{signed_url}"

    @staticmethod
    def _baixar_storage(path: str):
        encoded_path = path.replace(" ", "%20")
        try:
            with httpx.Client(timeout=30) as client:
                response = client.get(
                    f"{AttachmentService._base_storage_url()}/object/authenticated/{_BUCKET}/{encoded_path}",
                    headers=AttachmentService._headers(),
                )
            if response.status_code != 200:
                AttachmentService._falha_provedor("ler o documento", response)
            return response.content
        except httpx.HTTPError as erro:
            logger.exception("Falha de conexão com o Supabase Storage ao ler DOCX.")
            raise AttachmentError("Não foi possível ler o documento.", 502) from erro

    @staticmethod
    def _remover_storage(path: str):
        try:
            with httpx.Client(timeout=20) as client:
                response = client.delete(
                    f"{AttachmentService._base_storage_url()}/object/{_BUCKET}",
                    headers=AttachmentService._headers("application/json"),
                    json={"prefixes": [path]},
                )
            if response.status_code not in {200, 204}:
                AttachmentService._falha_provedor("remover o arquivo", response)
        except httpx.HTTPError as erro:
            logger.exception("Falha de conexão com o Supabase Storage ao remover arquivo.")
            raise AttachmentError("Não foi possível remover o arquivo do armazenamento.", 502) from erro

    @staticmethod
    def _falha_provedor(acao: str, response):
        logger.error(
            "Supabase Storage falhou ao %s (status=%s).",
            acao,
            response.status_code,
        )
        raise AttachmentError(f"Falha ao {acao} no armazenamento.", 502)
