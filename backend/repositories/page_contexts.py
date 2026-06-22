from services.supabase import supabase
from datetime import datetime
from typing import Optional, Dict

def save_page_context(
    user_id: str,
    url: str,
    domain: str,
    page_title: Optional[str] = None,
    html_summary: Optional[str] = None,
    session_id: Optional[str] = None
) -> Dict:
    """
    Salva o contexto de uma página visualizada pelo usuário.
    """
    context_data = {
        "user_id": user_id,
        "session_id": session_id,
        "url": url,
        "domain": domain,
        "page_title": page_title,
        "html_summary": html_summary,
        "created_at": datetime.utcnow().isoformat()
    }
    
    response = (
        supabase
        .table("page_contexts")
        .insert(context_data)
        .execute()
    )
    
    return response.data[0]

def get_latest_context(user_id: str) -> Optional[Dict]:
    """
    Busca o contexto mais recente do usuário.
    """
    response = (
        supabase
        .table("page_contexts")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .limit(1)
        .execute()
    )
    
    return response.data[0] if response.data else None
