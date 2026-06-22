from services.db_supabase import supabase
from datetime import datetime
from typing import Any, Dict, List, Optional


def log_generation(
    user_id: str,
    *,
    session_id: Optional[str] = None,
    intent_raw: Optional[str] = None,
    attempts: Optional[List[Any]] = None,
    errors: Optional[List[Any]] = None,
    final_plan: Optional[Dict[str, Any]] = None,
    model: Optional[str] = None,
    tokens_used: Optional[int] = None,
) -> List[Dict]:
    row = {
        "user_id": user_id,
        "session_id": session_id,
        "intent_raw": intent_raw,
        "attempts": attempts or [],
        "errors": errors or [],
        "final_plan": final_plan,
        "model": model,
        "tokens_used": tokens_used,
        "created_at": datetime.utcnow().isoformat(),
    }
    return supabase.table("automation_generation_logs").insert(row).execute().data or []
