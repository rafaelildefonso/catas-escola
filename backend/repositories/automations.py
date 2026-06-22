from services.db_supabase import supabase
from datetime import datetime
from typing import Any, Dict, List, Optional


def upsert_automation_run(
    run_id: str,
    user_id: str,
    *,
    automation_definition_id: Optional[str] = None,
    execution_id: Optional[str] = None,
    execution_run_id: Optional[str] = None,
    status: str = "running",
    run_type: str = "direct",
    input_summary: Optional[str] = None,
    input_payload: Optional[Dict[str, Any]] = None,
    result_metadata: Optional[Dict[str, Any]] = None,
    expires_at: Optional[str] = None,
) -> List[Dict]:
    row: Dict[str, Any] = {
        "id": run_id,
        "user_id": user_id,
        "correlation_id": run_id,
        "status": status,
        "run_type": run_type,
        "input_summary": input_summary or "",
        "input_payload": input_payload or {},
        "result_metadata": result_metadata or {},
        "expires_at": expires_at,
        "started_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat(),
    }
    if automation_definition_id:
        row["automation_id"] = automation_definition_id
    if execution_id:
        row["execution_id"] = execution_id
    if execution_run_id:
        row["execution_run_id"] = execution_run_id

    return (
        supabase.table("automation_runs")
        .upsert(row, on_conflict="id")
        .execute()
        .data
        or []
    )


def update_automation_run_execution(
    run_id: str, execution_id: str, execution_run_id: str | None = None
) -> List[Dict]:
    upd = {
        "execution_id": execution_id,
        "updated_at": datetime.utcnow().isoformat(),
    }
    if execution_run_id:
        upd["execution_run_id"] = execution_run_id

    return (
        supabase.table("automation_runs")
        .update(upd)
        .eq("id", run_id)
        .execute()
        .data
        or []
    )


def update_automation_run_status(
    run_id: str,
    status: str,
    *,
    result_metadata: Optional[Dict[str, Any]] = None,
    error_details: Optional[Dict[str, Any]] = None,
    steps_summary: Optional[Dict[str, Any]] = None,
) -> List[Dict]:
    upd: Dict[str, Any] = {
        "status": status,
        "updated_at": datetime.utcnow().isoformat(),
    }
    if status in ("completed", "failed", "canceled"):
        upd["finished_at"] = datetime.utcnow().isoformat()
    if result_metadata is not None:
        upd["result_metadata"] = result_metadata
    if error_details is not None:
        upd["error_details"] = error_details
    if steps_summary is not None:
        upd["steps_summary"] = steps_summary

    return (
        supabase.table("automation_runs")
        .update(upd)
        .eq("id", run_id)
        .execute()
        .data
        or []
    )




def log_step(
    automation_id: str,
    step_index: int,
    module_id: str,
    status: str,
    user_id: str = None,
    result: Optional[Dict[str, Any]] = None,
    intent: str = None,
) -> List[Dict]:
    row: Dict[str, Any] = {
        "automation_id": automation_id,
        "step_index": step_index,
        "module_id": module_id,
        "status": status,
        "updated_at": datetime.utcnow().isoformat(),
    }
    if user_id:
        row["user_id"] = user_id
    if result is not None:
        row["result"] = result
    if intent:
        row["intent"] = intent

    return (
        supabase.table("automation_step_logs")
        .upsert(row, on_conflict="automation_id, step_index")
        .execute()
        .data
        or []
    )


def get_user_stats(user_id: str) -> List[Dict]:
    """
    Retorna contagem de automações por dia da semana nos últimos 7 dias.
    """
    from datetime import timedelta
    seven_days_ago = (datetime.utcnow() - timedelta(days=7)).isoformat()

    res = (
        supabase.table("automation_runs")
        .select("created_at")
        .eq("user_id", user_id)
        .gte("created_at", seven_days_ago)
        .execute()
    )
    rows = res.data or []

    from collections import Counter
    weekdays = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sab"]
    counts: Counter = Counter()

    for r in rows:
        created = r.get("created_at")
        if created:
            try:
                dt = datetime.fromisoformat(created.replace("Z", "+00:00"))
                counts[weekdays[dt.weekday()]] += 1
            except (ValueError, IndexError):
                pass

    today = datetime.utcnow()
    current_weekday = today.weekday()

    data = []
    for i in range(7):
        day_index = (current_weekday + 1 + i) % 7
        day_name = weekdays[day_index]
        data.append({"name": day_name, "automations": counts.get(day_name, 0)})

    return data


def get_user_history(user_id: str, limit: int = 20) -> List[Dict]:
    res = (
        supabase.table("automation_runs")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .limit(limit)
        .execute()
    )
    rows = res.data or []
    out: List[Dict] = []
    for r in rows:
        payload = r.get("input_payload") or {}
        out.append(
            {
                "id": r.get("id"),
                "type": payload.get("action_type") or r.get("run_type") or "automation",
                "status": r.get("status"),
                "input_summary": r.get("input_summary"),
                "created_at": r.get("created_at"),
                "result_metadata": r.get("result_metadata") or {},
            }
        )
    return out
