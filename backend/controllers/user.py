from flask import Blueprint, request, jsonify, g
from core.security import get_current_user
from repositories import profiles

user_bp = Blueprint("user", __name__, url_prefix="/api/v1/user")


@user_bp.route("/me", methods=["GET"])
def get_user_profile():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    profile = profiles.get_user_profile(user_id)

    if not profile:
        profile = profiles.create_default_profile(user_id)

    quota_limit = profile.get("monthly_quota_limit", 500)
    quota_used = profile.get("quota_used", 0)
    quota_remaining = max(0, quota_limit - quota_used)

    return jsonify({
        "status": "success",
        "message": "Perfil recuperado com sucesso",
        "data": {
            "id": profile.get("id"),
            "email": current_user["email"],
            "display_name": profile.get("display_name"),
            "subscription_tier": profile.get("subscription_tier", "free"),
            "monthly_quota_limit": quota_limit,
            "quota_used": quota_used,
            "quota_remaining": quota_remaining,
            "last_quota_reset": profile.get("last_quota_reset"),
            "industry": profile.get("industry"),
            "role": profile.get("role"),
            "onboarding_completed": profile.get("onboarding_completed", False),
        }
    })


@user_bp.route("/me", methods=["PATCH"])
def update_profile():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    payload = request.get_json(silent=True) or {}

    allowed_fields = ["display_name", "photo_url", "industry", "role", "onboarding_completed", "onboarding_data"]
    updates = {k: v for k, v in payload.items() if k in allowed_fields}

    if not updates:
        return jsonify({"status": "success", "message": "Nenhuma alteração enviada"})

    profile = profiles.update_profile_info(user_id, updates)
    return jsonify({"status": "success", "data": profile})


@user_bp.route("/me", methods=["DELETE"])
def delete_account():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    profiles.delete_user_data(user_id)
    return jsonify({"status": "success", "message": "Conta removida com sucesso"})
