"""Create a durable run, then submit it to the automation worker."""

from datetime import datetime, timezone
import logging
import uuid

import httpx

from core.config import settings
from models.automation import Automation
from models.automation_run import AutomationRun
from extensions import db

logger = logging.getLogger(__name__)


def dispatch_automation(automation_id: str, user_id: str, run_type: str, trigger_payload=None):
    automation = Automation.query.filter_by(id=automation_id, user_id=user_id).first()
    if not automation:
        raise ValueError("Automação não encontrada")
    if automation.status != "active":
        raise ValueError("Ative a automação antes de executá-la")
    run_id = str(uuid.uuid4())
    run = AutomationRun(
        id=run_id,
        correlation_id=run_id,
        user_id=user_id,
        automation_id=automation.id,
        status="pending",
        run_type="direct",
        input_summary=automation.name,
        input_payload={"trigger_type": run_type, "trigger": trigger_payload or {}},
    )
    run.salvar()
    plan = {
        "name": automation.name,
        "description": automation.description,
        "trigger": automation.trigger,
        "steps": automation.steps,
    }
    try:
        with httpx.Client(timeout=10) as client:
            response = client.post(
                f"{settings.WORKER_URL.rstrip('/')}/execute",
                json={
                    # Os IDs têm semânticas diferentes: automation_id identifica
                    # o fluxo salvo e run_id identifica esta execução.
                    "automation_id": automation.id,
                    "run_id": run_id,
                    "plan": plan,
                    "user_id": user_id,
                    "trigger_payload": trigger_payload or {},
                },
                headers={"X-Worker-Secret": settings.WORKER_SHARED_SECRET},
            )
            response.raise_for_status()
            if response.status_code != 202:
                raise ValueError("Worker não aceitou a execução")
        AutomationRun.query.filter_by(id=run_id, status="pending").update(
            {"status": "running"}, synchronize_session=False
        )
        db.session.commit()
        db.session.refresh(run)
    except (httpx.HTTPError, ValueError):
        logger.exception("Worker indisponível para run %s", run_id)
        AutomationRun.query.filter_by(id=run_id, status="pending").update(
            {
                "status": "failed",
                "finished_at": datetime.now(timezone.utc),
                "error_details": {"message": "Worker indisponível para executar a automação"},
            },
            synchronize_session=False,
        )
        db.session.commit()
        db.session.refresh(run)
        try:
            from services.notification.notification_service import NotificationService

            NotificationService.notify_run(run_id, "failed")
        except Exception:
            logger.exception("Falha ao notificar execução %s", run_id)
    return run
