import hashlib
import hmac
import logging
import secrets
import uuid as uuid_lib
from flask import Blueprint, request, jsonify

from core.security import get_current_user
from services.database import get_sync_db
from models.db_models import UserWebhookConfig, Automation
from services.automation_runner_service import AutomationRunnerService

logger = logging.getLogger(__name__)

webhook_receiver_bp = Blueprint("webhook_receiver", __name__, url_prefix="/api/v1/webhooks")


def _get_webhook_config(slug: str):
    db = get_sync_db()
    try:
        config = (
            db.query(UserWebhookConfig)
            .filter(
                UserWebhookConfig.slug == slug,
                UserWebhookConfig.is_active == True,
            )
            .first()
        )
        return config.to_dict() if config else None
    finally:
        db.close()


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
        db = get_sync_db()
        try:
            auto = (
                db.query(Automation)
                .filter(Automation.id == config["automation_id"])
                .first()
            )
            if auto:
                plan["steps"] = auto.steps or []
                plan["name"] = auto.name or plan["name"]
        finally:
            db.close()

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

    db = get_sync_db()
    try:
        config_obj = UserWebhookConfig(**row)
        db.add(config_obj)
        db.flush()
        return jsonify(config_obj.to_dict())
    except Exception:
        return jsonify({"detail": "Erro ao criar webhook config."}), 500
    finally:
        db.close()


@webhook_receiver_bp.route("/configs", methods=["GET"])
def list_webhook_configs():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    db = get_sync_db()
    try:
        configs = (
            db.query(UserWebhookConfig)
            .filter(UserWebhookConfig.user_id == user_id)
            .order_by(UserWebhookConfig.created_at.desc())
            .all()
        )
        data = [c.to_dict() for c in configs]
        return jsonify({"status": "success", "data": data})
    finally:
        db.close()


@webhook_receiver_bp.route("/configs/<config_id>", methods=["DELETE"])
def delete_webhook_config(config_id):
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    db = get_sync_db()
    try:
        config = (
            db.query(UserWebhookConfig)
            .filter(
                UserWebhookConfig.id == config_id,
                UserWebhookConfig.user_id == user_id,
            )
            .first()
        )
        if not config:
            return jsonify({"detail": "Config não encontrada."}), 404
        config.is_active = False
        db.flush()
        return jsonify({"status": "success", "message": "Webhook desativado."})
    finally:
        db.close()
