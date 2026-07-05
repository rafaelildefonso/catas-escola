from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
from collections import Counter

from services.database import get_sync_db
from models.db_models import AutomationRun, AutomationStepLog
from sqlalchemy.dialects.postgresql import insert as pg_insert


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
    now = datetime.now(timezone.utc)
    row = {
        "id": run_id,
        "user_id": user_id,
        "correlation_id": run_id,
        "status": status,
        "run_type": run_type,
        "input_summary": input_summary or "",
        "input_payload": input_payload or {},
        "result_metadata": result_metadata or {},
        "expires_at": expires_at,
        "started_at": now,
        "updated_at": now,
    }
    if automation_definition_id:
        row["automation_id"] = automation_definition_id
    if execution_id:
        row["execution_id"] = execution_id
    if execution_run_id:
        row["execution_run_id"] = execution_run_id

    db = get_sync_db()
    try:
        stmt = pg_insert(AutomationRun).values(**row)
        stmt = stmt.on_conflict_do_update(
            index_elements=["id"],
            set_={k: stmt.excluded[k] for k in row if k != "id"},
        )
        db.execute(stmt)
        db.flush()

        result = db.query(AutomationRun).filter(AutomationRun.id == run_id).first()
        return [result.to_dict()] if result else []
    finally:
        db.close()


def update_automation_run_execution(
    run_id: str, execution_id: str, execution_run_id: str | None = None
) -> List[Dict]:
    db = get_sync_db()
    try:
        run = db.query(AutomationRun).filter(AutomationRun.id == run_id).first()
        if not run:
            return []
        run.execution_id = execution_id
        run.updated_at = datetime.now(timezone.utc)
        if execution_run_id:
            run.execution_run_id = execution_run_id
        db.flush()
        return [run.to_dict()]
    finally:
        db.close()


def update_automation_run_status(
    run_id: str,
    status: str,
    *,
    result_metadata: Optional[Dict[str, Any]] = None,
    error_details: Optional[Dict[str, Any]] = None,
    steps_summary: Optional[Dict[str, Any]] = None,
) -> List[Dict]:
    db = get_sync_db()
    try:
        run = db.query(AutomationRun).filter(AutomationRun.id == run_id).first()
        if not run:
            return []
        run.status = status
        run.updated_at = datetime.now(timezone.utc)
        if status in ("completed", "failed", "canceled"):
            run.finished_at = datetime.now(timezone.utc)
        if result_metadata is not None:
            run.result_metadata = result_metadata
        if error_details is not None:
            run.error_details = error_details
        if steps_summary is not None:
            run.steps_summary = steps_summary
        db.flush()
        return [run.to_dict()]
    finally:
        db.close()


def log_step(
    automation_id: str,
    step_index: int,
    module_id: str,
    status: str,
    user_id: str = None,
    result: Optional[Dict[str, Any]] = None,
    intent: str = None,
) -> List[Dict]:
    row = {
        "automation_id": automation_id,
        "step_index": step_index,
        "module_id": module_id,
        "status": status,
    }
    if user_id:
        row["user_id"] = user_id
    if result is not None:
        row["result"] = result
    if intent:
        row["intent"] = intent

    db = get_sync_db()
    try:
        stmt = pg_insert(AutomationStepLog).values(**row)
        stmt = stmt.on_conflict_do_update(
            constraint="automation_step_logs_automation_step_unique",
            set_={
                "module_id": stmt.excluded.module_id,
                "status": stmt.excluded.status,
                "result": stmt.excluded.result,
                "intent": stmt.excluded.intent,
            },
        )
        db.execute(stmt)
        db.flush()

        result_obj = (
            db.query(AutomationStepLog)
            .filter(
                AutomationStepLog.automation_id == automation_id,
                AutomationStepLog.step_index == step_index,
            )
            .first()
        )
        return [result_obj.to_dict()] if result_obj else []
    finally:
        db.close()


def get_user_stats(user_id: str) -> List[Dict]:
    seven_days_ago = datetime.now(timezone.utc) - timedelta(days=7)

    db = get_sync_db()
    try:
        rows = (
            db.query(AutomationRun.created_at)
            .filter(
                AutomationRun.user_id == user_id,
                AutomationRun.created_at >= seven_days_ago,
            )
            .all()
        )
    finally:
        db.close()

    weekdays = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sab"]
    counts: Counter = Counter()

    for r in rows:
        dt = r.created_at
        if dt:
            counts[weekdays[dt.weekday()]] += 1

    today = datetime.now(timezone.utc)
    current_weekday = today.weekday()

    data = []
    for i in range(7):
        day_index = (current_weekday + 1 + i) % 7
        day_name = weekdays[day_index]
        data.append({"name": day_name, "automations": counts.get(day_name, 0)})

    return data


def get_user_history(user_id: str, limit: int = 20) -> List[Dict]:
    db = get_sync_db()
    try:
        rows = (
            db.query(AutomationRun)
            .filter(AutomationRun.user_id == user_id)
            .order_by(AutomationRun.created_at.desc())
            .limit(limit)
            .all()
        )
    finally:
        db.close()

    out: List[Dict] = []
    for r in rows:
        d = r.to_dict()
        payload = d.get("input_payload") or {}
        out.append(
            {
                "id": d.get("id"),
                "type": payload.get("action_type") or d.get("run_type") or "automation",
                "status": d.get("status"),
                "input_summary": d.get("input_summary"),
                "created_at": d.get("created_at"),
                "result_metadata": d.get("result_metadata") or {},
            }
        )
    return out
