import logging

import httpx

from worker.modules.registry import register_module
from worker.utils.decorators import async_retry
from worker.utils.google_auth import get_google_access_token

logger = logging.getLogger(__name__)

SHEETS_API_BASE = "https://sheets.googleapis.com/v4/spreadsheets"


@register_module("google_sheets.append_row")
@async_retry(retries=3, delay=1.0, backoff=2.0)
async def sheets_append_row(params: dict) -> dict:
    user_id = params.get("user_id")
    spreadsheet_id = params.get("spreadsheet_id")
    range_ = params.get("range")
    values = params.get("values")

    if not all([user_id, spreadsheet_id, range_, values]):
        raise ValueError("Parâmetros obrigatórios: user_id, spreadsheet_id, range, values")

    if not isinstance(values, list) or not all(isinstance(row, list) for row in values):
        raise ValueError("'values' deve ser uma lista de listas (ex: [['A1', 'B1']])")

    token = get_google_access_token(user_id, "google_sheets")

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{SHEETS_API_BASE}/{spreadsheet_id}/values/{range_}:append",
            params={"valueInputOption": "USER_ENTERED", "insertDataOption": "INSERT_ROWS"},
            headers={"Authorization": f"Bearer {token}"},
            json={"values": values, "majorDimension": "ROWS"},
            timeout=30.0,
        )
        response.raise_for_status()
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

    if not all([user_id, spreadsheet_id, range_]):
        raise ValueError("Parâmetros obrigatórios: user_id, spreadsheet_id, range")

    token = get_google_access_token(user_id, "google_sheets")

    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{SHEETS_API_BASE}/{spreadsheet_id}/values/{range_}",
            headers={"Authorization": f"Bearer {token}"},
            timeout=30.0,
        )
        response.raise_for_status()
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

    if not all([user_id, spreadsheet_id, range_, values]):
        raise ValueError("Parâmetros obrigatórios: user_id, spreadsheet_id, range, values")

    if not isinstance(values, list) or not all(isinstance(row, list) for row in values):
        raise ValueError("'values' deve ser uma lista de listas (ex: [['novo_valor']])")

    token = get_google_access_token(user_id, "google_sheets")

    async with httpx.AsyncClient() as client:
        response = await client.put(
            f"{SHEETS_API_BASE}/{spreadsheet_id}/values/{range_}",
            params={"valueInputOption": "USER_ENTERED"},
            headers={"Authorization": f"Bearer {token}"},
            json={"values": values, "majorDimension": "ROWS"},
            timeout=30.0,
        )
        response.raise_for_status()
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
    title = params.get("title")

    if not all([user_id, title]):
        raise ValueError("Parâmetros obrigatórios: user_id, title")

    token = get_google_access_token(user_id, "google_sheets")

    async with httpx.AsyncClient() as client:
        response = await client.post(
            SHEETS_API_BASE,
            headers={"Authorization": f"Bearer {token}"},
            json={"properties": {"title": title}},
            timeout=30.0,
        )
        response.raise_for_status()
        data = response.json()

    spreadsheet_id = data.get("spreadsheetId")
    spreadsheet_url = data.get("spreadsheetUrl")
    logger.info(f"📊 Planilha criada: '{title}' — {spreadsheet_id}")
    return {
        "spreadsheet_id": spreadsheet_id,
        "spreadsheet_url": spreadsheet_url,
        "title": title,
    }

