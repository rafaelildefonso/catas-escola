import json
import logging
import mimetypes

import httpx

from worker.modules.registry import register_module
from worker.utils.decorators import async_retry
from worker.utils.google_auth import get_google_access_token

logger = logging.getLogger(__name__)

DRIVE_API_BASE = "https://www.googleapis.com/drive/v3"
DRIVE_UPLOAD_BASE = "https://www.googleapis.com/upload/drive/v3"


@register_module("google_drive.list_files")
@async_retry(retries=3, delay=1.0, backoff=2.0)
async def drive_list_files(params: dict) -> dict:
    user_id = params.get("user_id")
    query = params.get("query", "")
    max_results = params.get("max_results", 10)
    folder_id = params.get("folder_id")

    if not user_id:
        raise ValueError("Parâmetro obrigatório: user_id")

    token = get_google_access_token(user_id, "google_drive")

    q_parts = []
    if folder_id:
        q_parts.append(f"'{folder_id}' in parents")
    if query:
        q_parts.append(f"name contains '{query}'")
    q_parts.append("trashed = false")

    request_params = {
        "pageSize": max_results,
        "fields": "files(id,name,mimeType,size,modifiedTime,webViewLink,iconLink)",
        "orderBy": "modifiedTime desc",
        "q": " and ".join(q_parts),
    }

    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{DRIVE_API_BASE}/files",
            headers={"Authorization": f"Bearer {token}"},
            params=request_params,
            timeout=30.0,
        )
        response.raise_for_status()
        data = response.json()

    files = [
        {
            "file_id": f.get("id"),
            "name": f.get("name"),
            "mime_type": f.get("mimeType"),
            "size_bytes": f.get("size"),
            "modified_at": f.get("modifiedTime"),
            "web_link": f.get("webViewLink"),
        }
        for f in data.get("files", [])
    ]
    logger.info(f"📁 {len(files)} arquivo(s) encontrado(s) no Drive")
    return {"files": files, "count": len(files)}


@register_module("google_drive.upload_file")
@async_retry(retries=2, delay=2.0, backoff=2.0)
async def drive_upload_file(params: dict) -> dict:
    user_id = params.get("user_id")
    file_name = params.get("file_name")
    file_content = params.get("file_content")
    mime_type = params.get("mime_type")
    folder_id = params.get("folder_id")

    if not all([user_id, file_name, file_content]):
        raise ValueError("Parâmetros obrigatórios: user_id, file_name, file_content")

    if not mime_type:
        mime_type, _ = mimetypes.guess_type(file_name)
        mime_type = mime_type or "application/octet-stream"

    token = get_google_access_token(user_id, "google_drive")

    metadata: dict = {"name": file_name}
    if folder_id:
        metadata["parents"] = [folder_id]

    if isinstance(file_content, str):
        file_bytes = file_content.encode("utf-8")
    else:
        file_bytes = file_content

    boundary = "catas_drive_boundary"
    body = (
        f"--{boundary}\r\n"
        f"Content-Type: application/json; charset=UTF-8\r\n\r\n"
        f"{json.dumps(metadata)}\r\n"
        f"--{boundary}\r\n"
        f"Content-Type: {mime_type}\r\n\r\n"
    ).encode("utf-8") + file_bytes + f"\r\n--{boundary}--".encode("utf-8")

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{DRIVE_UPLOAD_BASE}/files",
            params={"uploadType": "multipart"},
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": f"multipart/related; boundary={boundary}",
            },
            content=body,
            timeout=60.0,
        )
        response.raise_for_status()
        data = response.json()

    file_id = data.get("id")
    logger.info(f"📁 Arquivo '{file_name}' enviado para o Drive — id: {file_id}")
    return {
        "file_id": file_id,
        "file_name": file_name,
        "mime_type": mime_type,
        "web_link": f"https://drive.google.com/file/d/{file_id}/view",
    }


@register_module("google_drive.get_file_content")
@async_retry(retries=3, delay=1.0, backoff=2.0)
async def drive_get_file_content(params: dict) -> dict:
    user_id = params.get("user_id")
    file_id = params.get("file_id")
    max_chars = params.get("max_chars", 5000)

    if not all([user_id, file_id]):
        raise ValueError("Parâmetros obrigatórios: user_id, file_id")

    token = get_google_access_token(user_id, "google_drive")
    headers = {"Authorization": f"Bearer {token}"}

    async with httpx.AsyncClient() as client:
        # Fetch file metadata first to get name and mimeType
        meta_resp = await client.get(
            f"{DRIVE_API_BASE}/files/{file_id}",
            headers=headers,
            params={"fields": "id,name,mimeType,size"},
            timeout=15.0,
        )
        meta_resp.raise_for_status()
        meta = meta_resp.json()

        mime_type = meta.get("mimeType", "")

        # Google Docs/Sheets/Slides must be exported, not downloaded directly
        export_mime_map = {
            "application/vnd.google-apps.document": "text/plain",
            "application/vnd.google-apps.spreadsheet": "text/csv",
            "application/vnd.google-apps.presentation": "text/plain",
        }

        if mime_type in export_mime_map:
            export_mime = export_mime_map[mime_type]
            content_resp = await client.get(
                f"{DRIVE_API_BASE}/files/{file_id}/export",
                headers=headers,
                params={"mimeType": export_mime},
                timeout=30.0,
            )
        else:
            content_resp = await client.get(
                f"{DRIVE_API_BASE}/files/{file_id}",
                headers=headers,
                params={"alt": "media"},
                timeout=30.0,
            )

        content_resp.raise_for_status()
        content = content_resp.text[:max_chars]

    logger.info(f"📁 Conteúdo lido de '{meta.get('name')}' ({len(content)} chars)")
    return {
        "file_id": file_id,
        "file_name": meta.get("name"),
        "mime_type": mime_type,
        "content": content,
        "truncated": len(content_resp.text) > max_chars,
    }


@register_module("google_drive.create_folder")
@async_retry(retries=3, delay=1.0, backoff=2.0)
async def drive_create_folder(params: dict) -> dict:
    user_id = params.get("user_id")
    folder_name = params.get("folder_name")
    parent_folder_id = params.get("parent_folder_id")

    if not all([user_id, folder_name]):
        raise ValueError("Parâmetros obrigatórios: user_id, folder_name")

    token = get_google_access_token(user_id, "google_drive")

    metadata = {"name": folder_name, "mimeType": "application/vnd.google-apps.folder"}
    if parent_folder_id:
        metadata["parents"] = [parent_folder_id]

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{DRIVE_API_BASE}/files",
            headers={"Authorization": f"Bearer {token}"},
            json=metadata,
            timeout=30.0,
        )
        response.raise_for_status()
        data = response.json()

    folder_id = data.get("id")
    logger.info(f"📁 Pasta '{folder_name}' criada no Drive — id: {folder_id}")
    return {
        "folder_id": folder_id,
        "folder_name": folder_name,
        "web_link": f"https://drive.google.com/drive/folders/{folder_id}",
    }
