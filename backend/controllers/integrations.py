import secrets
from datetime import datetime, timedelta, timezone
from pathlib import Path
from flask import Blueprint, request, jsonify

from core.security import get_current_user
from core.errors import sanitize_error
from repositories import integrations as int_repo
from services.db_supabase import supabase
from services.oauth_token_service import (
    exchange_google_auth_code,
    get_google_auth_url,
)

integrations_bp = Blueprint("integrations", __name__, url_prefix="/api/v1/integrations")

_TEMPLATES_DIR = Path(__file__).resolve().parent.parent / "templates"


def _render_result(status: str, title: str, message: str):
    path = _TEMPLATES_DIR / "integration_result.html"
    html = path.read_text(encoding="utf-8")
    icon = "&#10003;" if status == "success" else "&#10005;"
    html = html.replace("{{status}}", status)
    html = html.replace("{{icon}}", icon)
    html = html.replace("{{title}}", title)
    html = html.replace("{{message}}", message)
    return html, 200, {"Content-Type": "text/html; charset=utf-8"}


_oauth_states: dict[str, dict] = {}


@integrations_bp.route("/google/auth-url", methods=["GET"])
def google_auth_url():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    provider = request.args.get("provider", "")

    state = secrets.token_urlsafe(32)
    _oauth_states[state] = {
        "user_id": user_id,
        "provider": provider,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    base_url = request.base_url.rstrip("/").replace("/google/auth-url", "")
    redirect_uri = f"{base_url}/api/v1/integrations/google/callback"
    auth_url = get_google_auth_url(provider, redirect_uri, state)

    if not auth_url:
        return jsonify({"detail": "GOOGLE_CLIENT_ID não configurado no servidor."}), 500

    return jsonify({"auth_url": auth_url, "state": state})


@integrations_bp.route("/google/callback", methods=["GET"])
def google_callback():
    code = request.args.get("code")
    state = request.args.get("state")
    error = request.args.get("error")

    if error:
        return _render_result("error", "Autorização negada", error)

    state_data = _oauth_states.pop(state, None)
    if not state_data:
        return _render_result("error", "Link expirado", "Esta solicitação expirou ou é inválida.")

    base_url = request.base_url.rstrip("/")
    redirect_uri = base_url
    tokens = exchange_google_auth_code(code, redirect_uri)

    if not tokens:
        return _render_result("error", "Erro ao conectar", "Não foi possível concluir a conexão.")

    access_token = tokens.get("access_token")
    refresh_token = tokens.get("refresh_token")
    expires_in = tokens.get("expires_in")

    expires_at = None
    if isinstance(expires_in, (int, float)):
        expires_at = (datetime.now(timezone.utc) + timedelta(seconds=int(expires_in))).isoformat()

    int_repo.save_integration(
        user_id=state_data["user_id"],
        provider=state_data["provider"],
        access_token=access_token,
        refresh_token=refresh_token,
        expires_at=expires_at,
    )

    return _render_result("success", "Conectado!", "Sua integração foi conectada com sucesso.")


@integrations_bp.route("", methods=["GET"])
def list_integrations():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    try:
        data = int_repo.get_user_integrations(user_id)
        return jsonify({"status": "success", "data": data})
    except Exception as e:
        return jsonify({"detail": sanitize_error(e, "Erro ao listar integrações")}), 500


@integrations_bp.route("/<provider>/connect", methods=["POST"])
def connect_integration(provider):
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    data = request.get_json(silent=True) or {}

    try:
        result = int_repo.save_integration(
            user_id=user_id,
            provider=provider,
            access_token=data.get("access_token"),
            refresh_token=data.get("refresh_token"),
            expires_at=data.get("expires_at"),
            settings=data.get("settings")
        )
        return jsonify({"status": "success", "data": result})
    except Exception as e:
        return jsonify({"detail": sanitize_error(e, "Erro ao conectar integração")}), 500


@integrations_bp.route("/<provider>", methods=["DELETE"])
def disconnect_integration(provider):
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    try:
        supabase.table("integrations").delete().eq("user_id", user_id).eq("provider", provider).execute()
        return jsonify({"status": "success", "message": f"{provider} desconectado com sucesso"})
    except Exception as e:
        return jsonify({"detail": sanitize_error(e, "Erro ao desconectar integração")}), 500
