from datetime import datetime, timezone, timedelta
from typing import Optional, List, Dict

from services.database import get_sync_db
from models.db_models import Integration
from core.crypto import encrypt_value, decrypt_value
from services.oauth_token_service import (
    is_google_provider,
    refresh_google_tokens,
    token_expires_soon,
)
from sqlalchemy.dialects.postgresql import insert as pg_insert


def get_user_integrations(user_id: str) -> List[Dict]:
    db = get_sync_db()
    try:
        rows = (
            db.query(Integration)
            .filter(Integration.user_id == user_id)
            .all()
        )
        data = [r.to_dict() for r in rows]
        for item in data:
            item.pop("access_token", None)
            item.pop("refresh_token", None)
        return data
    finally:
        db.close()


def get_integration(user_id: str, provider: str) -> Optional[Dict]:
    db = get_sync_db()
    try:
        integration_obj = (
            db.query(Integration)
            .filter(
                Integration.user_id == user_id,
                Integration.provider == provider,
            )
            .first()
        )
        if not integration_obj:
            return None

        integration = integration_obj.to_dict()

        if integration.get("access_token"):
            integration["access_token"] = decrypt_value(integration["access_token"])
        if integration.get("refresh_token"):
            integration["refresh_token"] = decrypt_value(integration["refresh_token"])

        _maybe_refresh_tokens(user_id, provider, integration)

        return integration
    finally:
        db.close()


def _maybe_refresh_tokens(user_id: str, provider: str, integration: Dict) -> None:
    if not is_google_provider(provider):
        return
    if not token_expires_soon(integration.get("token_expires_at")):
        return
    rt = integration.get("refresh_token")
    if not rt:
        return
    data = refresh_google_tokens(rt)
    if not data:
        return
    new_access = data.get("access_token")
    if not new_access:
        return
    new_refresh = data.get("refresh_token") or rt
    expires_in = data.get("expires_in")
    expires_at = None
    if isinstance(expires_in, int):
        expires_at = (
            datetime.now(timezone.utc) + timedelta(seconds=expires_in)
        ).isoformat()
    save_integration(
        user_id,
        provider,
        new_access,
        refresh_token=new_refresh,
        expires_at=expires_at,
        settings=integration.get("settings") or {},
    )
    integration["access_token"] = new_access
    integration["refresh_token"] = new_refresh
    integration["token_expires_at"] = expires_at


def save_integration(
    user_id: str,
    provider: str,
    access_token: str,
    refresh_token: Optional[str] = None,
    expires_at: Optional[str] = None,
    settings: Optional[Dict] = None
) -> Dict:
    integration_data = {
        "user_id": user_id,
        "provider": provider,
        "access_token": encrypt_value(access_token),
        "refresh_token": encrypt_value(refresh_token) if refresh_token else None,
        "token_expires_at": expires_at,
        "is_connected": True,
        "settings": settings or {},
    }

    db = get_sync_db()
    try:
        stmt = pg_insert(Integration).values(**integration_data)
        stmt = stmt.on_conflict_do_update(
            constraint="integrations_user_id_provider_key",
            set_={
                "access_token": stmt.excluded.access_token,
                "refresh_token": stmt.excluded.refresh_token,
                "token_expires_at": stmt.excluded.token_expires_at,
                "is_connected": stmt.excluded.is_connected,
                "settings": stmt.excluded.settings,
            },
        )
        db.execute(stmt)
        db.flush()

        result = (
            db.query(Integration)
            .filter(
                Integration.user_id == user_id,
                Integration.provider == provider,
            )
            .first()
        )
        saved_data = result.to_dict() if result else {}
        saved_data.pop("access_token", None)
        saved_data.pop("refresh_token", None)
        return saved_data
    finally:
        db.close()


def delete_integration(user_id: str, provider: str) -> None:
    db = get_sync_db()
    try:
        db.query(Integration).filter(
            Integration.user_id == user_id,
            Integration.provider == provider,
        ).delete()
        db.flush()
    finally:
        db.close()
