from typing import Optional, Dict

from services.database import get_sync_db
from models.db_models import AiSuggestion


def save_suggestion(
    user_id: str,
    title: str,
    context_id: Optional[str] = None,
    description: Optional[str] = None,
    confidence_score: Optional[float] = None,
    payload_preview: Optional[Dict] = None,
    suggested_workflow: Optional[str] = None
) -> Dict:
    db = get_sync_db()
    try:
        suggestion = AiSuggestion(
            user_id=user_id,
            context_id=context_id,
            title=title,
            description=description,
            confidence_score=confidence_score,
            payload_preview=payload_preview,
            suggested_workflow=suggested_workflow,
        )
        db.add(suggestion)
        db.flush()
        return suggestion.to_dict()
    finally:
        db.close()


def update_suggestion_status(suggestion_id: str, status: str) -> Dict:
    db = get_sync_db()
    try:
        suggestion = db.query(AiSuggestion).filter(AiSuggestion.id == suggestion_id).first()
        if not suggestion:
            raise RuntimeError(f"Sugestão {suggestion_id} não encontrada")
        suggestion.status = status
        db.flush()
        return suggestion.to_dict()
    finally:
        db.close()
