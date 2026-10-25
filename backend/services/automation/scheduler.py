"""Single dedicated scheduler process; atomically claims due UTC automations."""

import logging
import time
from datetime import datetime, timezone

from application import create_app
from extensions import db
from models.automation import Automation
from services.automation.dispatch import dispatch_automation
from services.automation.schedule import next_run_at

logger = logging.getLogger(__name__)


def bootstrap_schedules():
    """Populate due times for active schedules created before this process started."""
    automations = Automation.query.filter_by(status="active", next_run_at=None).all()
    for automation in automations:
        trigger = automation.trigger or {}
        if trigger.get("type") not in {"cron", "schedule"}:
            continue
        try:
            due = next_run_at(trigger)
            automation.next_run_at = due.replace(tzinfo=None) if due else None
        except ValueError:
            logger.exception("Agendamento inválido na automação %s", automation.id)
    db.session.commit()


def tick():
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    due = (
        Automation.query.filter(Automation.status == "active", Automation.next_run_at <= now)
        .order_by(Automation.next_run_at)
        .limit(100)
        .all()
    )
    for automation in due:
        old_due = automation.next_run_at
        next_due = next_run_at(
            automation.trigger or {}, now.replace(tzinfo=timezone.utc)
        )
        next_due = next_due.replace(tzinfo=None) if next_due else None
        claimed = (
            Automation.query.filter_by(id=automation.id, status="active", next_run_at=old_due)
            .update({"next_run_at": next_due}, synchronize_session=False)
        )
        db.session.commit()
        if claimed:
            dispatch_automation(
                automation.id,
                automation.user_id,
                "schedule",
                {"scheduled_at": old_due.isoformat() + "Z"},
            )


def main():
    app = create_app()
    with app.app_context():
        bootstrap_schedules()
    while True:
        try:
            with app.app_context():
                tick()
        except Exception:
            logger.exception("Falha no ciclo do scheduler")
        time.sleep(15)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    main()
