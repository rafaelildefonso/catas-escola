import hashlib
import hmac
import logging
import secrets
import uuid as uuid_lib
from flask import Blueprint, request, jsonify

from core.security import get_current_user
from services.db_supabase import supabase
from services.automation_runner_service import AutomationRunnerService

logger = logging.getLogger(__name__)

webhook_receiver_bp = Blueprint("webhook_receiver", __name__, url_prefix="/api/v1/webhooks")


def _get_webhook_config(slug: str):
    res = (
        supabase.table("user_webhook_configs")
        .select("*")
        .eq("slug", slug)
        .eq("is_active", True)
        .single()
        .execute()
    )
    return res.data


def _verify_hmac(secret: str, body: bytes, signature_header: str) -> bool:
    expected = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    received = signature_header.removeprefix("sha256=")
    return hmac.compare_digest(expected, received)


@webhook_receiver_bp.route("/trigger/<slug>", methods=["POST"])
def trigger_from_webhook(slug):
    body = request.get_data()
    signature = request.headers.get("X-Webhook-Signature", "")

    config = _get_webhook_config(slug)
    if not config:
        return jsonify({"detail": "Webhook não encontrado ou inativo."}), 404

    if not _verify_hmac(config["hmac_secret"], body, signature):
        logger.warning("HMAC inválido para webhook slug=%s", slug)
        return jsonify({"detail": "Assinatura inválida."}), 401

    try:
        payload = request.get_json(silent=True) or {}
    except Exception:
        payload = {}

    run_id = str(uuid_lib.uuid4())
    plan = {
        "automation_id": run_id,
        "user_id": config["user_id"],
        "name": config.get("name", "Webhook Automation"),
        "steps": [],
        "context": {},
    }

    if config.get("automation_id"):
        auto_res = (
            supabase.table("automations")
            .select("steps, name")
            .eq("id", config["automation_id"])
            .single()
            .execute()
        )
        if auto_res.data:
            plan["steps"] = auto_res.data.get("steps", [])
            plan["name"] = auto_res.data.get("name", plan["name"])

    try:
        result = AutomationRunnerService.trigger_automation_from_webhook(
            run_id, plan, payload, user_id=config["user_id"]
        )
        logger.info("Webhook '%s' disparou execução %s", slug, result["id"])
        return jsonify({"status": "accepted", "execution_id": result["id"]})
    except Exception as e:
        logger.error("Erro ao disparar webhook automation: %s", e)
        return jsonify({"detail": "Erro interno ao processar webhook."}), 500


@webhook_receiver_bp.route("/configs", methods=["POST"])
def create_webhook_config():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    data = request.get_json(silent=True) or {}
    slug = f"wh-{user_id[:6]}-{secrets.token_urlsafe(8)}"
    hmac_secret = secrets.token_hex(32)

    row = {
        "user_id": user_id,
        "slug": slug,
        "name": data.get("name"),
        "description": data.get("description"),
        "automation_id": data.get("automation_id"),
        "hmac_secret": hmac_secret,
        "allowed_sources": data.get("allowed_sources") or [],
    }

    res = supabase.table("user_webhook_configs").insert(row).execute()
    if not res.data:
        return jsonify({"detail": "Erro ao criar webhook config."}), 500

    return jsonify(res.data[0])


@webhook_receiver_bp.route("/configs", methods=["GET"])
def list_webhook_configs():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    res = (
        supabase.table("user_webhook_configs")
        .select("id, slug, name, description, automation_id, is_active, created_at")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .execute()
    )
    return jsonify({"status": "success", "data": res.data or []})


@webhook_receiver_bp.route("/configs/<config_id>", methods=["DELETE"])
def delete_webhook_config(config_id):
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    res = (
        supabase.table("user_webhook_configs")
        .update({"is_active": False})
        .eq("id", config_id)
        .eq("user_id", user_id)
        .execute()
    )
    if not res.data:
        return jsonify({"detail": "Config não encontrada."}), 404
    return jsonify({"status": "success", "message": "Webhook desativado."})
