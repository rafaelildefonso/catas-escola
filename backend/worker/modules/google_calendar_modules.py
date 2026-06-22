import logging

import httpx

from worker.modules.registry import register_module
from worker.utils.decorators import async_retry
from worker.utils.google_auth import get_google_access_token

logger = logging.getLogger(__name__)

CALENDAR_API_BASE = "https://www.googleapis.com/calendar/v3/calendars/primary"


@register_module("google_calendar.create_event")
@async_retry(retries=3, delay=1.0, backoff=2.0)
async def calendar_create_event(params: dict) -> dict:
    user_id = params.get("user_id")
    summary = params.get("summary")
    start = params.get("start")
    end = params.get("end")
    description = params.get("description", "")
    location = params.get("location", "")
    timezone = params.get("timezone", "America/Sao_Paulo")

    if not all([user_id, summary, start, end]):
        raise ValueError("Parâmetros obrigatórios: user_id, summary, start, end")

    token = get_google_access_token(user_id, "google_calendar")

    event_body = {
        "summary": summary,
        "description": description,
        "location": location,
        "start": {"dateTime": start, "timeZone": timezone},
        "end": {"dateTime": end, "timeZone": timezone},
    }

    async with httpx.AsyncClient() as client:
        response = await client.post(
            CALENDAR_API_BASE + "/events",
            headers={"Authorization": f"Bearer {token}"},
            json=event_body,
            timeout=30.0,
        )
        response.raise_for_status()
        data = response.json()

    logger.info(f"📅 Evento criado: '{summary}' — {data.get('id')}")
    return {
        "event_id": data.get("id"),
        "html_link": data.get("htmlLink"),
        "summary": summary,
        "start": start,
        "end": end,
    }


@register_module("google_calendar.list_events")
@async_retry(retries=3, delay=1.0, backoff=2.0)
async def calendar_list_events(params: dict) -> dict:
    user_id = params.get("user_id")
    time_min = params.get("time_min")
    time_max = params.get("time_max")
    max_results = params.get("max_results", 10)
    query = params.get("query")

    if not user_id:
        raise ValueError("Parâmetro obrigatório: user_id")

    token = get_google_access_token(user_id, "google_calendar")

    query_params = {
        "maxResults": max_results,
        "orderBy": "startTime",
        "singleEvents": "true",
    }
    if time_min:
        query_params["timeMin"] = time_min
    if time_max:
        query_params["timeMax"] = time_max
    if query:
        query_params["q"] = query

    async with httpx.AsyncClient() as client:
        response = await client.get(
            CALENDAR_API_BASE + "/events",
            headers={"Authorization": f"Bearer {token}"},
            params=query_params,
            timeout=30.0,
        )
        response.raise_for_status()
        data = response.json()

    items = data.get("items", [])
    events = [
        {
            "event_id": e.get("id"),
            "summary": e.get("summary", "(Sem título)"),
            "start": e.get("start", {}).get("dateTime") or e.get("start", {}).get("date"),
            "end": e.get("end", {}).get("dateTime") or e.get("end", {}).get("date"),
            "location": e.get("location", ""),
            "description": e.get("description", ""),
            "html_link": e.get("htmlLink"),
        }
        for e in items
    ]
    logger.info(f"📅 {len(events)} evento(s) encontrado(s)")
    return {"events": events, "count": len(events)}


@register_module("google_calendar.update_event")
@async_retry(retries=3, delay=1.0, backoff=2.0)
async def calendar_update_event(params: dict) -> dict:
    user_id = params.get("user_id")
    event_id = params.get("event_id")
    summary = params.get("summary")
    start = params.get("start")
    end = params.get("end")
    description = params.get("description")
    location = params.get("location")
    timezone = params.get("timezone", "America/Sao_Paulo")

    if not all([user_id, event_id]):
        raise ValueError("Parâmetros obrigatórios: user_id, event_id")

    token = get_google_access_token(user_id, "google_calendar")

    patch_body = {}
    if summary:
        patch_body["summary"] = summary
    if description is not None:
        patch_body["description"] = description
    if location is not None:
        patch_body["location"] = location
    if start:
        patch_body["start"] = {"dateTime": start, "timeZone": timezone}
    if end:
        patch_body["end"] = {"dateTime": end, "timeZone": timezone}

    if not patch_body:
        raise ValueError("Nenhum campo para atualizar foi fornecido.")

    async with httpx.AsyncClient() as client:
        response = await client.patch(
            f"{CALENDAR_API_BASE}/events/{event_id}",
            headers={"Authorization": f"Bearer {token}"},
            json=patch_body,
            timeout=30.0,
        )
        response.raise_for_status()
        data = response.json()

    logger.info(f"📅 Evento atualizado: {event_id}")
    return {
        "event_id": data.get("id"),
        "summary": data.get("summary"),
        "html_link": data.get("htmlLink"),
    }


@register_module("google_calendar.delete_event")
@async_retry(retries=3, delay=1.0, backoff=2.0)
async def calendar_delete_event(params: dict) -> dict:
    user_id = params.get("user_id")
    event_id = params.get("event_id")

    if not all([user_id, event_id]):
        raise ValueError("Parâmetros obrigatórios: user_id, event_id")

    token = get_google_access_token(user_id, "google_calendar")

    async with httpx.AsyncClient() as client:
        response = await client.delete(
            f"{CALENDAR_API_BASE}/events/{event_id}",
            headers={"Authorization": f"Bearer {token}"},
            timeout=30.0,
        )
        response.raise_for_status()

    logger.info(f"📅 Evento deletado: {event_id}")
    return {"event_id": event_id, "deleted": True}

