from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from services.database import get_sync_db
from models.db_models import AutomationGenerationLog


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
    db = get_sync_db()
    try:
        row = AutomationGenerationLog(
            user_id=user_id,
            session_id=session_id,
            intent_raw=intent_raw,
            attempts=attempts or [],
            errors=errors or [],
            final_plan=final_plan,
            model=model,
            tokens_used=tokens_used,
        )
        db.add(row)
        db.commit()
        return [row.to_dict()]
    finally:
        db.close()
