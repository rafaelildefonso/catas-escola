import logging
import re
from urllib.parse import quote

import httpx

from worker.modules.registry import register_module
from worker.utils.decorators import async_retry
from worker.utils.google_auth import get_google_access_token

logger = logging.getLogger(__name__)

SHEETS_API_BASE = "https://sheets.googleapis.com/v4/spreadsheets"
_SPREADSHEET_ID_RE = re.compile(r"^[A-Za-z0-9_-]{20,}$")
_DEFAULT_HEADER_COLORS = ("#FDE68A", "#BFDBFE", "#BBF7D0", "#E9D5FF", "#FBCFE8")


def _spreadsheet_id(value) -> str:
    """Accept a Google Sheets URL or its ID, but never an invented placeholder."""
    candidate = str(value or "").strip()
    match = re.search(r"/spreadsheets/d/([A-Za-z0-9_-]+)", candidate)
    if match:
        candidate = match.group(1)
    if not _SPREADSHEET_ID_RE.fullmatch(candidate):
        raise ValueError(
            "Informe uma planilha válida. Cole o link do Google Planilhas ou o ID que aparece entre '/d/' e '/edit'."
        )
    return candidate


def _values_url(spreadsheet_id: str, range_: str) -> str:
    return f"{SHEETS_API_BASE}/{spreadsheet_id}/values/{quote(range_, safe='!:$')}"


def _raise_for_google_error(response: httpx.Response, action: str) -> None:
    try:
        response.raise_for_status()
    except httpx.HTTPStatusError as exc:
        detail = ""
        try:
            detail = response.json().get("error", {}).get("message", "")
        except ValueError:
            pass
        if response.status_code in {400, 401, 403, 404}:
            raise ValueError(
                f"Não foi possível {action} no Google Planilhas. "
                f"{detail or 'Confira o acesso à planilha e tente novamente.'}"
            ) from exc
        raise


def _column_label(index: int) -> str:
    label = ""
    while index:
        index, remainder = divmod(index - 1, 26)
        label = chr(65 + remainder) + label
    return label


def _hex_to_rgb(color: str) -> dict:
    value = str(color or "").strip().lstrip("#")
    if not re.fullmatch(r"[0-9a-fA-F]{6}", value):
        value = "E5E7EB"
    return {
        "red": int(value[0:2], 16) / 255,
        "green": int(value[2:4], 16) / 255,
        "blue": int(value[4:6], 16) / 255,
    }


@register_module("google_sheets.append_row")
@async_retry(retries=3, delay=1.0, backoff=2.0)
async def sheets_append_row(params: dict) -> dict:
    user_id = params.get("user_id")
    spreadsheet_id = params.get("spreadsheet_id")
    range_ = params.get("range")
    values = params.get("values")

    spreadsheet_id = _spreadsheet_id(spreadsheet_id)

    if not all([user_id, spreadsheet_id, range_, values]):
        raise ValueError("Parâmetros obrigatórios: user_id, spreadsheet_id, range, values")

    if not isinstance(values, list) or not all(isinstance(row, list) for row in values):
        raise ValueError("'values' deve ser uma lista de listas (ex: [['A1', 'B1']])")

    token = get_google_access_token(user_id, "google_sheets")

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{_values_url(spreadsheet_id, range_)}:append",
            params={"valueInputOption": "USER_ENTERED", "insertDataOption": "INSERT_ROWS"},
            headers={"Authorization": f"Bearer {token}"},
            json={"values": values, "majorDimension": "ROWS"},
            timeout=30.0,
        )
        _raise_for_google_error(response, "adicionar os dados")
        data = response.json()

    updates = data.get("updates", {})
    logger.info(f"📊 {updates.get('updatedRows', 0)} linha(s) adicionada(s) em {spreadsheet_id}")
    return {
        "spreadsheet_id": spreadsheet_id,
        "updated_range": updates.get("updatedRange"),
        "updated_rows": updates.get("updatedRows"),
    }


@register_module("google_sheets.get_values")
@async_retry(retries=3, delay=1.0, backoff=2.0)
async def sheets_get_values(params: dict) -> dict:
    user_id = params.get("user_id")
    spreadsheet_id = params.get("spreadsheet_id")
    range_ = params.get("range")

    spreadsheet_id = _spreadsheet_id(spreadsheet_id)

    if not all([user_id, spreadsheet_id, range_]):
        raise ValueError("Parâmetros obrigatórios: user_id, spreadsheet_id, range")

    token = get_google_access_token(user_id, "google_sheets")

    async with httpx.AsyncClient() as client:
        response = await client.get(
            _values_url(spreadsheet_id, range_),
            headers={"Authorization": f"Bearer {token}"},
            timeout=30.0,
        )
        _raise_for_google_error(response, "ler a planilha")
        data = response.json()

    values = data.get("values", [])
    logger.info(f"📊 {len(values)} linha(s) lida(s) de '{range_}' em {spreadsheet_id}")
    return {
        "spreadsheet_id": spreadsheet_id,
        "range": data.get("range"),
        "values": values,
        "row_count": len(values),
    }


@register_module("google_sheets.update_values")
@async_retry(retries=3, delay=1.0, backoff=2.0)
async def sheets_update_values(params: dict) -> dict:
    user_id = params.get("user_id")
    spreadsheet_id = params.get("spreadsheet_id")
    range_ = params.get("range")
    values = params.get("values")

    spreadsheet_id = _spreadsheet_id(spreadsheet_id)

    if not all([user_id, spreadsheet_id, range_, values]):
        raise ValueError("Parâmetros obrigatórios: user_id, spreadsheet_id, range, values")

    if not isinstance(values, list) or not all(isinstance(row, list) for row in values):
        raise ValueError("'values' deve ser uma lista de listas (ex: [['novo_valor']])")

    token = get_google_access_token(user_id, "google_sheets")

    async with httpx.AsyncClient() as client:
        response = await client.put(
            _values_url(spreadsheet_id, range_),
            params={"valueInputOption": "USER_ENTERED"},
            headers={"Authorization": f"Bearer {token}"},
            json={"values": values, "majorDimension": "ROWS"},
            timeout=30.0,
        )
        _raise_for_google_error(response, "atualizar os dados")
        data = response.json()

    logger.info(f"📊 {data.get('updatedCells', 0)} célula(s) atualizada(s) em {spreadsheet_id}")
    return {
        "spreadsheet_id": spreadsheet_id,
        "updated_range": data.get("updatedRange"),
        "updated_rows": data.get("updatedRows"),
        "updated_cells": data.get("updatedCells"),
    }


@register_module("google_sheets.create_spreadsheet")
@async_retry(retries=3, delay=1.0, backoff=2.0)
async def sheets_create_spreadsheet(params: dict) -> dict:
    user_id = params.get("user_id")
    title = str(params.get("title") or "").strip()
    sheet_title = str(params.get("sheet_title") or "Tarefas").strip() or "Tarefas"
    headers = params.get("headers") or []
    header_colors = params.get("header_colors") or []

    if len(title) > 100 or title.casefold() in {"primary", "planilha_id", "spreadsheet_id"}:
        raise ValueError("Informe um nome válido para a nova planilha.")
    if not isinstance(headers, list) or not all(isinstance(item, str) and item.strip() for item in headers):
        raise ValueError("Os cabeçalhos da planilha devem ser uma lista de textos.")
    if not isinstance(header_colors, list) or not all(isinstance(color, str) for color in header_colors):
        raise ValueError("As cores dos cabeçalhos devem ser uma lista de cores.")
    if len(headers) > 50:
        raise ValueError("A planilha pode ter no máximo 50 cabeçalhos por vez.")

    if not all([user_id, title]):
        raise ValueError("Parâmetros obrigatórios: user_id, title")

    token = get_google_access_token(user_id, "google_sheets")

    async with httpx.AsyncClient() as client:
        response = await client.post(
            SHEETS_API_BASE,
            headers={"Authorization": f"Bearer {token}"},
            json={
                "properties": {"title": title},
                "sheets": [{"properties": {"title": sheet_title}}],
            },
            timeout=30.0,
        )
        _raise_for_google_error(response, "criar a planilha")
        data = response.json()

        spreadsheet_id = data.get("spreadsheetId")
        if not spreadsheet_id:
            raise ValueError("O Google Planilhas não retornou o identificador da nova planilha.")

        if headers:
            header_range = f"'{sheet_title}'!A1:{_column_label(len(headers))}1"
            write_response = await client.put(
                _values_url(spreadsheet_id, header_range),
                params={"valueInputOption": "USER_ENTERED"},
                headers={"Authorization": f"Bearer {token}"},
                json={"values": [headers], "majorDimension": "ROWS"},
                timeout=30.0,
            )
            _raise_for_google_error(write_response, "adicionar os cabeçalhos")

            sheet_id = (data.get("sheets") or [{}])[0].get("properties", {}).get("sheetId", 0)
            requests = []
            for index, _ in enumerate(headers):
                color = header_colors[index] if index < len(header_colors) else _DEFAULT_HEADER_COLORS[index % len(_DEFAULT_HEADER_COLORS)]
                requests.append({
                    "repeatCell": {
                        "range": {
                            "sheetId": sheet_id,
                            "startRowIndex": 0,
                            "endRowIndex": 1,
                            "startColumnIndex": index,
                            "endColumnIndex": index + 1,
                        },
                        "cell": {
                            "userEnteredFormat": {
                                "backgroundColor": _hex_to_rgb(color),
                                "textFormat": {"bold": True},
                            }
                        },
                        "fields": "userEnteredFormat(backgroundColor,textFormat)",
                    }
                })
            format_response = await client.post(
                f"{SHEETS_API_BASE}/{spreadsheet_id}:batchUpdate",
                headers={"Authorization": f"Bearer {token}"},
                json={"requests": requests},
                timeout=30.0,
            )
            _raise_for_google_error(format_response, "formatar os cabeçalhos")

    spreadsheet_url = data.get("spreadsheetUrl")
    logger.info(f"📊 Planilha criada: '{title}' — {spreadsheet_id}")
    return {
        "spreadsheet_id": spreadsheet_id,
        "spreadsheet_url": spreadsheet_url,
        "title": title,
        "sheet_title": sheet_title,
        "headers": headers,
    }

