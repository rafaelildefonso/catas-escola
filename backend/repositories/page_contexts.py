from typing import Optional, Dict

from services.database import get_sync_db
from models.db_models import PageContext


def save_page_context(
    user_id: str,
    url: str,
    domain: str,
    page_title: Optional[str] = None,
    html_summary: Optional[str] = None,
    session_id: Optional[str] = None
) -> Dict:
    db = get_sync_db()
    try:
        context = PageContext(
            user_id=user_id,
            session_id=session_id,
            url=url,
            domain=domain,
            page_title=page_title,
            html_summary=html_summary,
        )
        db.add(context)
        db.flush()
        return context.to_dict()
    finally:
        db.close()


def get_latest_context(user_id: str) -> Optional[Dict]:
    db = get_sync_db()
    try:
        context = (
            db.query(PageContext)
            .filter(PageContext.user_id == user_id)
            .order_by(PageContext.created_at.desc())
            .first()
        )
        return context.to_dict() if context else None
    finally:
        db.close()
