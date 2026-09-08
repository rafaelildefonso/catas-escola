from flask import request, jsonify, redirect
from core.security import get_current_user
from services.integration.google_auth_service import gerar_auth_url, processar_callback, _frontend_url


class GoogleIntegrationController:

    @staticmethod
    def auth_url():
        user = get_current_user()
        if not user:
            return jsonify({"detail": "Nao autorizado"}), 401

        provider = request.args.get("provider")
        if not provider:
            return jsonify({"detail": "provider e obrigatorio"}), 400

        url = gerar_auth_url(user["id"], provider)
        if not url:
            return jsonify({"detail": "Provider nao suportado"}), 400

        return jsonify({"auth_url": url}), 200

    @staticmethod
    def callback():
        code = request.args.get("code")
        state = request.args.get("state")

        if not code or not state:
            return redirect(f"{_frontend_url()}/integrations?error=missing_params")

        try:
            result = processar_callback(code, state)
            return redirect(result["redirect_url"])
        except Exception as e:
            return redirect(f"{_frontend_url()}/integrations?error=callback_failed")
