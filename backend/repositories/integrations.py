from services.db_supabase import supabase
from datetime import datetime, timezone, timedelta
from typing import Optional, List, Dict
from core.crypto import encrypt_value, decrypt_value
from services.oauth_token_service import (
    is_google_provider,
    refresh_google_tokens,
    token_expires_soon,
)

def get_user_integrations(user_id: str) -> List[Dict]:
    """
    Busca todas as integrações de um usuário.
    """
    response = (
        supabase
        .table("integrations")
        .select("*")
        .eq("user_id", user_id)
        .execute()
    )
    
    data = response.data or []
    # Descriptografar tokens para uso interno/exibição se necessário (idealmente não retornar para o front)
    # Apenas enviamos metadata para o front, não os tokens
    for item in data:
        # Limpar tokens para não irem pro front-end na listagem
        item.pop("access_token", None)
        item.pop("refresh_token", None)
        
    return data

def get_integration(user_id: str, provider: str) -> Optional[Dict]:
    """
    Busca uma integração específica por provedor e descriptografa para uso interno.
    """
    response = (
        supabase
        .table("integrations")
        .select("*")
        .eq("user_id", user_id)
        .eq("provider", provider)
        .execute()
    )
    
    if not response.data:
        return None
        
    integration = response.data[0]
    
    if integration.get("access_token"):
        integration["access_token"] = decrypt_value(integration["access_token"])
    if integration.get("refresh_token"):
        integration["refresh_token"] = decrypt_value(integration["refresh_token"])

    _maybe_refresh_tokens(user_id, provider, integration)

    return integration


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
    """
    Salva ou atualiza uma integração (upsert) criptografando os tokens.
    """
    integration_data = {
        "user_id": user_id,
        "provider": provider,
        "access_token": encrypt_value(access_token),
        "refresh_token": encrypt_value(refresh_token) if refresh_token else None,
        "token_expires_at": expires_at,
        "is_connected": True,
        "settings": settings or {},
        "updated_at": datetime.utcnow().isoformat()
    }
    
    response = (
        supabase
        .table("integrations")
        .upsert(integration_data, on_conflict="user_id,provider")
        .execute()
    )
    
    saved_data = response.data[0]
    # Remove os tokens criptografados antes de retornar ao router
    saved_data.pop("access_token", None)
    saved_data.pop("refresh_token", None)
    return saved_data
