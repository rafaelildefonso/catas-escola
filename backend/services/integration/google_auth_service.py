import os
from datetime import datetime, timedelta, timezone
from typing import Optional
from urllib.parse import urlencode
from itsdangerous import URLSafeTimedSerializer, BadSignature, SignatureExpired

from models.integration import Integration
from core.config import settings
from core.oauth_token_service import (
    get_google_auth_url,
    exchange_google_auth_code,
    is_google_provider,
)
from core.crypto import encrypt_value


def _build_state(user_id: str, provider: str) -> str:
    return URLSafeTimedSerializer(settings.JWT_SECRET_KEY, salt="google-oauth-state").dumps(
        {"uid": user_id, "p": provider}
    )


def decode_state(state: str):
    try:
        payload = URLSafeTimedSerializer(settings.JWT_SECRET_KEY, salt="google-oauth-state").loads(
            state, max_age=600
        )
    except (BadSignature, SignatureExpired) as exc:
        raise ValueError("Estado OAuth invalido ou expirado") from exc
    if not isinstance(payload, dict) or not payload.get("uid") or not is_google_provider(payload.get("p")):
        raise ValueError("Estado OAuth invalido")
    return payload["uid"], payload["p"]


def _frontend_url() -> str:
    return os.getenv("FRONTEND_URL", "http://localhost:52159").rstrip("/")


def montar_url_retorno_integracoes(**params: str) -> str:
    return f"{_frontend_url()}/app/integrations?{urlencode(params)}"


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
        "redirect_url": montar_url_retorno_integracoes(connected=provider),
    }
