import base64
import json
import os
from datetime import datetime, timedelta, timezone
from typing import Optional

from models.integration import Integration
from core.oauth_token_service import (
    get_google_auth_url,
    exchange_google_auth_code,
    is_google_provider,
)
from core.crypto import encrypt_value


def _build_state(user_id: str, provider: str) -> str:
    payload = json.dumps({"uid": user_id, "p": provider})
    return base64.urlsafe_b64encode(payload.encode()).decode()


def decode_state(state: str):
    payload = json.loads(base64.urlsafe_b64decode(state.encode()))
    return payload["uid"], payload["p"]


def _frontend_url() -> str:
    return os.getenv("FRONTEND_URL", "http://localhost:52159")


def gerar_auth_url(user_id: str, provider: str) -> Optional[str]:
    if not is_google_provider(provider):
        return None

    state = _build_state(user_id, provider)
    redirect_uri = os.getenv(
        "GOOGLE_INTEGRATION_REDIRECT_URI",
        "http://localhost:8000/api/v1/integrations/google/callback",
    )
    return get_google_auth_url(provider, redirect_uri, state)


def processar_callback(code: str, state: str) -> dict:
    user_id, provider = decode_state(state)

    redirect_uri = os.getenv(
        "GOOGLE_INTEGRATION_REDIRECT_URI",
        "http://localhost:8000/api/v1/integrations/google/callback",
    )
    tokens = exchange_google_auth_code(code, redirect_uri)
    if not tokens:
        raise ValueError("Falha ao trocar code por tokens Google")

    access_token = tokens.get("access_token", "")
    refresh_token = tokens.get("refresh_token", "")
    expires_in = tokens.get("expires_in", 3600)
    expires_at = datetime.now(timezone.utc) + timedelta(seconds=int(expires_in))

    existing = Integration.query.filter_by(
        user_id=user_id, provider=provider
    ).first()

    if existing:
        existing.atualizar(
            access_token=encrypt_value(access_token),
            refresh_token=encrypt_value(refresh_token) if refresh_token else None,
            token_expires_at=expires_at,
            is_connected=True,
        )
        integration = existing
    else:
        integration = Integration(
            user_id=user_id,
            provider=provider,
            is_connected=True,
            access_token=encrypt_value(access_token),
            refresh_token=encrypt_value(refresh_token) if refresh_token else None,
            token_expires_at=expires_at,
        )
        integration.salvar()

    return {
        "success": True,
        "provider": provider,
        "redirect_url": f"{_frontend_url()}/integrations?connected={provider}",
    }
