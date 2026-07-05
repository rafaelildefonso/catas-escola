from datetime import datetime, timezone
from typing import Optional, List, Dict

from services.database import get_sync_db
from models.db_models import ExecutionLog


def log_automation(
    user_id: str,
    workflow_name: Optional[str] = None,
    status: str = 'running',
    input_data: Optional[Dict] = None,
    suggestion_id: Optional[str] = None,
    session_id: Optional[str] = None,
    result_data: Optional[Dict] = None
) -> Dict:
    if status not in ['success', 'failed', 'running']:
        raise ValueError(f"Status inválido: {status}. Deve ser 'success', 'failed' ou 'running'")

    db = get_sync_db()
    try:
        log = ExecutionLog(
            user_id=user_id,
            workflow_name=workflow_name,
            status=status,
            input_data=input_data,
            result_data=result_data,
            suggestion_id=suggestion_id,
            session_id=session_id,
        )
        db.add(log)
        db.flush()
        return log.to_dict()
    finally:
        db.close()


def get_user_execution_logs(user_id: str, limit: int = 50) -> List[Dict]:
    db = get_sync_db()
    try:
        logs = (
            db.query(ExecutionLog)
            .filter(ExecutionLog.user_id == user_id)
            .order_by(ExecutionLog.started_at.desc())
            .limit(limit)
            .all()
        )
        return [log.to_dict() for log in logs]
    finally:
        db.close()


def update_execution_log(
    log_id: str,
    status: str,
    result_data: Optional[Dict] = None,
    error_message: Optional[str] = None
) -> Dict:
    db = get_sync_db()
    try:
        log = db.query(ExecutionLog).filter(ExecutionLog.id == log_id).first()
        if not log:
            raise RuntimeError(f"Log {log_id} não encontrado")
        log.status = status
        log.finished_at = datetime.now(timezone.utc)
        if result_data:
            log.result_data = result_data
        if error_message:
            log.error_message = error_message
        db.flush()
        return log.to_dict()
    finally:
        db.close()
