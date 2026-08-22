import re
import os
from functools import wraps
from flask import request, jsonify, g
from jose import jwt, JWTError

from core.config import settings


def get_current_user():
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return None

    token = auth_header.split(" ", 1)[1]

    if token == "dev-token" and os.getenv("ENVIRONMENT", "development") == "development":
        DEV_USER_ID = os.getenv("DEV_USER_ID", "dev-user-0000-0000-0000-000000000001")
        user = {
            "id": DEV_USER_ID,
            "email": "developer@catas.app",
            "token": "dev-token",
        }
        g.current_user = user
        return user

    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=["HS256"],
        )
        user_id = payload.get("user_id")
        email = payload.get("email", "")
        if not user_id:
            return None

        user = {
            "id": user_id,
            "email": email,
            "token": token,
        }
        g.current_user = user
        return user
    except JWTError:
        return None


def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        user = get_current_user()
        if not user:
            return jsonify({"detail": "Não autorizado"}), 401
        return f(*args, **kwargs)
    return decorated_function


FORBIDDEN_PATTERNS = [
    r"(?i)ignore\s+previous\s+instructions",
    r"(?i)forget\s+all\s+guidelines",
    r"(?i)ignore\s+all\s+the\s+instructions",
    r"(?i)you\s+are\s+now\s+a\s+bot\s+that",
    r"(?i)system\s+prompt:",
    r"(?i)\[INST\]",
    r"(?i)\[/INST\]",
    r"(?i)human:",
    r"(?i)assistant:",
    r"(?i)you\s+must\s+print\s+the\s+original\s+instructions",
    r"(?i)show\s+me\s+your\s+prompt",
]


def is_prompt_injection_safe(text: str) -> bool:
    if not text:
        return True
    for pattern in FORBIDDEN_PATTERNS:
        if re.search(pattern, text):
            return False
    return True


def get_user_rate_limit(user_id: str) -> str:
    import uuid as uuid_lib

    try:
        uuid_lib.UUID(str(user_id))
    except (ValueError, TypeError):
        return "100/minute"

    try:
        from app.models.profile import Profile

        profile = Profile.buscar_por_id(user_id)
        if not profile:
            return "100/minute"

        tier = (profile.subscription_tier or "basic").lower()

        if tier == "max":
            return "500/minute"
        elif tier == "pro":
            return "200/minute"
        else:
            return "100/minute"
    except Exception:
        return "50/minute"
