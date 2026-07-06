from uuid import uuid4
from datetime import datetime, timezone

from flask import Blueprint, request, jsonify

from app.extensions import db
from app.models.user import User
from app.models.profile import Profile
from core.security import get_current_user

auth_bp = Blueprint("auth", __name__, url_prefix="/api/v1/auth")


@auth_bp.route("/signup", methods=["POST"])
def signup():
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""

    if not email or not password:
        return jsonify({"detail": "Email e senha são obrigatórios."}), 400

    if "@" not in email:
        return jsonify({"detail": "Email inválido."}), 400

    if len(password) < 8:
        return jsonify({"detail": "Senha deve ter no mínimo 8 caracteres."}), 400

    existing = User.query.filter_by(email=email).first()
    if existing:
        return jsonify({"detail": "Email já cadastrado."}), 409

    user_id = str(uuid4())
    user = User(id=user_id, email=email)
    user.set_password(password)
    db.session.add(user)

    profile = Profile(
        id=user_id,
        subscription_tier="basic",
        quota_used=0,
        last_quota_reset=datetime.now(timezone.utc),
    )
    db.session.add(profile)
    db.session.commit()

    token = user.generate_token()
    return jsonify({
        "token": token,
        "user": user.to_dict(),
        "profile": profile.to_dict(),
    }), 201


@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""

    if not email or not password:
        return jsonify({"detail": "Email e senha são obrigatórios."}), 400

    user = User.query.filter_by(email=email).first()
    if not user or not user.check_password(password):
        return jsonify({"detail": "Email ou senha inválidos."}), 401

    profile = Profile.buscar_por_id(user.id)
    if not profile:
        profile = Profile(id=user.id, subscription_tier="basic")
        db.session.add(profile)
        db.session.commit()

    token = user.generate_token()
    return jsonify({
        "token": token,
        "user": user.to_dict(),
        "profile": profile.to_dict(),
    })


@auth_bp.route("/me", methods=["GET"])
def me():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    user = User.query.get(user_id)
    if not user:
        return jsonify({"detail": "Usuário não encontrado"}), 404

    profile = Profile.buscar_por_id(user_id)
    if not profile:
        profile = Profile(id=user_id, subscription_tier="basic")
        db.session.add(profile)
        db.session.commit()

    return jsonify({
        "user": user.to_dict(),
        "profile": profile.to_dict(),
    })
