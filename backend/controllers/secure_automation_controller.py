"""Authenticated HTTP handlers for owner-scoped automation resources."""

from flask import g, jsonify, request

from core.security import login_required
from services.automation.scoped_resources import ScopedAutomationResources as Resources


def _not_found(exc):
    return jsonify({"detail": str(exc)}), 404


class SecureAutomationRunController:
    @staticmethod
    @login_required
    def listar():
        try:
            limit = min(max(int(request.args.get("limit", 20)), 1), 100)
            offset = max(int(request.args.get("offset", 0)), 0)
        except ValueError:
            return jsonify({"detail": "Paginação inválida"}), 400
        return jsonify(Resources.list_runs(g.current_user["id"], limit, offset)), 200

    @staticmethod
    @login_required
    def buscar_por_id(id):
        try:
            return jsonify(Resources.get_run(g.current_user["id"], id)), 200
        except ValueError as exc:
            return _not_found(exc)

    @staticmethod
    @login_required
    def deletar(id):
        try:
            Resources.delete_run(g.current_user["id"], id)
            return "", 204
        except ValueError as exc:
            return _not_found(exc)

    @staticmethod
    @login_required
    def metodo_nao_permitido(id=None):
        return jsonify({"detail": "Execuções são gerenciadas pelo servidor"}), 405


class SecureStepLogController:
    @staticmethod
    @login_required
    def listar():
        run_id = request.args.get("run_id")
        if not run_id:
            return jsonify({"detail": "run_id é obrigatório"}), 400
        try:
            return jsonify(Resources.list_logs(g.current_user["id"], run_id)), 200
        except ValueError as exc:
            return _not_found(exc)

    @staticmethod
    @login_required
    def buscar_por_id(id):
        try:
            return jsonify(Resources.get_log(g.current_user["id"], id)), 200
        except ValueError as exc:
            return _not_found(exc)

    @staticmethod
    @login_required
    def metodo_nao_permitido(id=None):
        return jsonify({"detail": "Logs são gerenciados pelo servidor"}), 405


class SecureDeviceController:
    @staticmethod
    @login_required
    def criar():
        data = request.get_json(silent=True) or {}
        token = data.get("fcm_token")
        platform = data.get("platform")
        if not isinstance(token, str) or not 20 <= len(token) <= 4096 or platform not in {"android", "ios", "web"}:
            return jsonify({"detail": "Token ou plataforma inválidos"}), 400
        return jsonify(Resources.upsert_device(g.current_user["id"], token, platform)), 200

    @staticmethod
    @login_required
    def listar():
        return jsonify(Resources.list_devices(g.current_user["id"])), 200

    @staticmethod
    @login_required
    def buscar_por_id(id):
        try:
            return jsonify(Resources.get_device(g.current_user["id"], id)), 200
        except ValueError as exc:
            return _not_found(exc)

    @staticmethod
    @login_required
    def atualizar(id):
        data = request.get_json(silent=True) or {}
        if set(data) != {"active"} or not isinstance(data["active"], bool):
            return jsonify({"detail": "Informe somente active"}), 400
        try:
            return jsonify(Resources.set_device_active(g.current_user["id"], id, data["active"])), 200
        except ValueError as exc:
            return _not_found(exc)

    @staticmethod
    @login_required
    def deletar(id):
        try:
            Resources.delete_device(g.current_user["id"], id)
            return "", 204
        except ValueError as exc:
            return _not_found(exc)
