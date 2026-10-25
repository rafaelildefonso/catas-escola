"""Persist automation alerts and send best-effort Firebase push notifications."""

import logging

from extensions import db
from models.notification import Notification
from models.user_device import UserDevice

logger = logging.getLogger(__name__)


class NotificationService:
    @staticmethod
    def list_for_user(user_id: str):
        return (
            Notification.query.filter_by(user_id=user_id)
            .order_by(Notification.created_at.desc())
            .limit(100)
            .all()
        )

    @staticmethod
    def mark_read(user_id: str, notification_id: str):
        notification = Notification.query.filter_by(id=notification_id, user_id=user_id).first()
        if not notification:
            raise ValueError("Notificação não encontrada")
        notification.is_read = True
        db.session.commit()
        return notification

    @staticmethod
    def notify_run(run_id: str, status: str):
        from models.automation_run import AutomationRun

        run = AutomationRun.query.filter_by(id=run_id).first()
        if not run or not run.user_id or status not in {"completed", "failed"}:
            return
        title = "Automação concluída" if status == "completed" else "Falha na automação"
        body = run.input_summary or "Sua automação foi atualizada."
        notification = Notification(
            user_id=run.user_id,
            title=title,
            body=body,
            action_type="app_route",
            action_data=f"/app/automations/{run_id}",
            extra_data={"run_id": run_id, "status": status},
        )
        db.session.add(notification)
        db.session.commit()
        try:
            from application import init_firebase
            from firebase_admin import messaging

            init_firebase()
            tokens = [
                device.fcm_token
                for device in UserDevice.query.filter_by(user_id=run.user_id, active=True).all()
            ]
            for token in tokens:
                try:
                    messaging.send(messaging.Message(
                        token=token,
                        notification=messaging.Notification(title=title, body=body),
                        data={"run_id": run_id, "status": status},
                    ))
                except Exception:
                    logger.exception("Falha ao enviar push para run %s", run_id)
        except Exception:
            logger.exception("FCM indisponível para run %s", run_id)
