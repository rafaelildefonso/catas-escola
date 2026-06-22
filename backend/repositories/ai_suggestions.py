from services.supabase import supabase
from datetime import datetime
from typing import Optional, Dict

def save_suggestion(
    user_id: str,
    title: str,
    context_id: Optional[str] = None,
    description: Optional[str] = None,
    confidence_score: Optional[float] = None,
    payload_preview: Optional[Dict] = None,
    suggested_workflow: Optional[str] = None
) -> Dict:
    """
    Salva uma sugestão gerada pela IA.
    """
    suggestion_data = {
        "user_id": user_id,
        "context_id": context_id,
        "title": title,
        "description": description,
        "confidence_score": confidence_score,
        "payload_preview": payload_preview,
        "suggested_workflow": suggested_workflow,
        "status": "pending",
        "created_at": datetime.utcnow().isoformat()
    }
    
    response = (
        supabase
        .table("ai_suggestions")
        .insert(suggestion_data)
        .execute()
    )
    
    return response.data[0]

def update_suggestion_status(suggestion_id: str, status: str) -> Dict:
    """
    Atualiza o status de uma sugestão ('accepted', 'rejected', 'executed').
    """
    response = (
        supabase
        .table("ai_suggestions")
        .update({"status": status})
        .eq("id", suggestion_id)
        .execute()
    )
    
    return response.data[0]
