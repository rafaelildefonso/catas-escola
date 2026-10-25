from flask import g, jsonify

from core.security import login_required
from services.notification.notification_service import NotificationService


class NotificationController:
    @staticmethod
    @login_required
    def listar():
        return jsonify([item.to_dict() for item in NotificationService.list_for_user(g.current_user["id"])]), 200

    @staticmethod
    @login_required
    def marcar_lida(notification_id):
        try:
            item = NotificationService.mark_read(g.current_user["id"], notification_id)
            return jsonify(item.to_dict()), 200
        except ValueError as exc:
            return jsonify({"detail": str(exc)}), 404
