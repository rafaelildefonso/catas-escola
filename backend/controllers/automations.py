import uuid
from datetime import datetime, timedelta
from flask import Blueprint, request, jsonify
from core.security import get_current_user
from core.errors import sanitize_error
from repositories import automations
from services.automation_runner_service import AutomationRunnerService

automations_bp = Blueprint("automations", __name__, url_prefix="/api/v1/automations")


@automations_bp.route("/trigger", methods=["POST"])
def trigger_automation():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    data = request.get_json(silent=True) or {}
    plan = data.get("plan", {})
    context = data.get("context", {})

    automation_id = str(uuid.uuid4())

    from repositories import profiles as profiles_repo
    profile = profiles_repo.get_user_profile(user_id) or {}
    tier = profile.get("subscription_tier", "basic")

    expires_at = None
    if tier == "basic":
        expires_at = (datetime.utcnow() + timedelta(days=7)).isoformat()

    automations.upsert_automation_run(
        automation_id,
        user_id,
        status="running",
        run_type="direct",
        input_summary=(plan.get("name") or "Automação")[:500],
        input_payload={"plan": plan, "context": context},
        expires_at=expires_at,
    )

    enriched_plan = {
        **plan,
        "automation_id": automation_id,
        "user_id": user_id,
        "context": context,
    }

    try:
        result = AutomationRunnerService.start_automation(automation_id, enriched_plan, user_id=user_id)
        automations.update_automation_run_execution(automation_id, result["id"])
        return jsonify({
            "status": "success",
            "automation_id": automation_id,
            "execution_id": result["id"],
        })
    except Exception as e:
        return jsonify({"detail": sanitize_error(e, "Erro ao executar automação")}), 500


@automations_bp.route("/history", methods=["GET"])
def get_history():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    limit = request.args.get("limit", 20, type=int)

    try:
        results = automations.get_user_history(user_id, limit)
    except Exception as e:
        return jsonify({"detail": f"Erro ao buscar histórico: {sanitize_error(e)}"}), 500

    return jsonify({"status": "success", "data": results})


@automations_bp.route("/stats", methods=["GET"])
def get_stats():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]

    try:
        data = automations.get_user_stats(user_id)
    except Exception as e:
        return jsonify({"detail": f"Erro ao buscar estatísticas: {sanitize_error(e)}"}), 500

    return jsonify({"status": "success", "data": data})
