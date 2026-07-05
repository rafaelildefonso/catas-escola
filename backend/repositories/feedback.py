from typing import Dict, Optional

from services.database import get_sync_db
from models.db_models import MessageFeedback, Message
from sqlalchemy.dialects.postgresql import insert as pg_insert


def upsert_feedback(
    message_id: str,
    user_id: str,
    session_id: str,
    is_liked: bool,
    reason: Optional[str] = None,
) -> Dict:
    payload = {
        "message_id": message_id,
        "user_id": user_id,
        "session_id": session_id,
        "is_liked": is_liked,
    }
    if reason is not None:
        payload["reason"] = reason

    db = get_sync_db()
    try:
        stmt = pg_insert(MessageFeedback).values(**payload)
        stmt = stmt.on_conflict_do_update(
            constraint="uq_feedback_message_user",
            set_={
                "is_liked": stmt.excluded.is_liked,
                "reason": stmt.excluded.reason,
            },
        )
        db.execute(stmt)
        db.flush()

        result = (
            db.query(MessageFeedback)
            .filter(
                MessageFeedback.message_id == message_id,
                MessageFeedback.user_id == user_id,
            )
            .first()
        )
        if not result:
            raise RuntimeError("Upsert retornou sem dados")
        return result.to_dict()
    except Exception as e:
        raise RuntimeError(f"Erro ao salvar feedback: {e}")
    finally:
        db.close()


def delete_feedback(message_id: str, user_id: str) -> bool:
    db = get_sync_db()
    try:
        db.query(MessageFeedback).filter(
            MessageFeedback.message_id == message_id,
            MessageFeedback.user_id == user_id,
        ).delete()
        db.flush()
        return True
    except Exception as e:
        raise RuntimeError(f"Erro ao remover feedback: {e}")
    finally:
        db.close()


def get_feedback_summary(session_id: str) -> Dict:
    db = get_sync_db()
    try:
        rows = (
            db.query(MessageFeedback.is_liked)
            .filter(MessageFeedback.session_id == session_id)
            .all()
        )
        likes = sum(1 for r in rows if r.is_liked is True)
        dislikes = sum(1 for r in rows if r.is_liked is False)
        return {"total": len(rows), "likes": likes, "dislikes": dislikes}
    except Exception as e:
        raise RuntimeError(f"Erro ao buscar resumo de feedback: {e}")
    finally:
        db.close()


def get_recent_liked_messages(user_id: str, limit: int = 3) -> list[str]:
    db = get_sync_db()
    try:
        results = (
            db.query(Message.content)
            .join(Message, MessageFeedback.message_id == Message.id)
            .filter(
                MessageFeedback.user_id == user_id,
                MessageFeedback.is_liked == True,
            )
            .order_by(MessageFeedback.updated_at.desc())
            .limit(limit)
            .all()
        )
        return [r.content for r in results if r.content]
    except Exception as e:
        print(f"⚠️ Erro ao buscar feedbacks positivos para RAG: {e}")
        return []
    finally:
        db.close()


def get_user_preferences_summary(user_id: str) -> Dict[str, int]:
    db = get_sync_db()
    try:
        rows = (
            db.query(MessageFeedback.is_liked, MessageFeedback.reason)
            .filter(MessageFeedback.user_id == user_id)
            .all()
        )
        positive_reasons = {}
        negative_reasons = {}

        for row in rows:
            if row.is_liked is True and row.reason:
                positive_reasons[row.reason] = positive_reasons.get(row.reason, 0) + 1
            elif row.is_liked is False and row.reason:
                negative_reasons[row.reason] = negative_reasons.get(row.reason, 0) + 1

        return {
            "positive": positive_reasons,
            "negative": negative_reasons,
            "total": len(rows),
        }
    except Exception as e:
        print(f"⚠️ Erro ao buscar preferências do usuário: {e}")
        return {"positive": {}, "negative": {}, "total": 0}
    finally:
        db.close()
