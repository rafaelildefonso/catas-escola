import uuid as uuid_lib
from datetime import datetime, timezone
from typing import Optional, List, Dict

from services.database import get_sync_db
from models.db_models import ChatSession, Message


def create_session(user_id: str, title: Optional[str] = None, is_onboarding: bool = False) -> Dict:
    if user_id.startswith("dev-user-"):
        return {
            "id": f"dev-session-{user_id}",
            "user_id": user_id,
            "title": title or "Nova Conversa",
            "is_onboarding": is_onboarding,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat()
        }

    db = get_sync_db()
    try:
        session = ChatSession(
            user_id=uuid_lib.UUID(user_id),
            title=title or "Nova Conversa",
            is_onboarding=is_onboarding,
        )
        db.add(session)
        db.commit()
        return session.to_dict()
    except Exception as e:
        raise RuntimeError(f"Erro ao criar sessão: {e}")
    finally:
        db.close()


def get_user_sessions(user_id: str, limit: int = 50, offset: int = 0) -> List[Dict]:
    db = get_sync_db()
    try:
        sessions = (
            db.query(ChatSession)
            .filter(ChatSession.user_id == uuid_lib.UUID(user_id))
            .order_by(ChatSession.updated_at.desc())
            .offset(offset)
            .limit(limit)
            .all()
        )
        return [s.to_dict() for s in sessions]
    except Exception as e:
        raise RuntimeError(f"Erro ao buscar sessões: {e}")
    finally:
        db.close()


def get_session(session_id: str, user_id: str) -> Optional[Dict]:
    if session_id and session_id.startswith("dev-session-"):
        if "-" in session_id:
            parts = session_id.split("-")
            if len(parts) >= 3 and parts[0] == "dev" and parts[1] == "session":
                extracted_user_id = "-".join(parts[2:])
                if extracted_user_id.startswith("dev-user-"):
                    return {
                        "id": session_id,
                        "user_id": extracted_user_id,
                        "title": "Nova Conversa",
                        "is_onboarding": False,
                        "created_at": datetime.now(timezone.utc).isoformat(),
                        "updated_at": datetime.now(timezone.utc).isoformat()
                    }

    db = get_sync_db()
    try:
        session = (
            db.query(ChatSession)
            .filter(
                ChatSession.id == uuid_lib.UUID(session_id),
                ChatSession.user_id == uuid_lib.UUID(user_id),
            )
            .first()
        )
        return session.to_dict() if session else None
    except Exception:
        return None
    finally:
        db.close()


def get_session_messages(session_id: str, user_id: str, limit: int = 100, offset: int = 0) -> List[Dict]:
    session = get_session(session_id, user_id)
    if not session:
        raise ValueError(f"Sessão {session_id} não encontrada ou não pertence ao usuário")

    db = get_sync_db()
    try:
        messages = (
            db.query(Message)
            .filter(Message.session_id == uuid_lib.UUID(session_id))
            .order_by(Message.created_at.asc())
            .offset(offset)
            .limit(limit)
            .all()
        )
        return [m.to_dict() for m in messages]
    except Exception as e:
        raise RuntimeError(f"Erro ao buscar mensagens: {e}")
    finally:
        db.close()


def save_message(
    session_id: str,
    role: str,
    content: str,
    metadata: Optional[Dict] = None
) -> Dict:
    if role not in ['user', 'assistant', 'system']:
        raise ValueError(f"Role inválido: {role}. Deve ser 'user', 'assistant' ou 'system'")

    db = get_sync_db()
    try:
        msg = Message(
            session_id=uuid_lib.UUID(session_id),
            role=role,
            content=content,
            metadata_=metadata or {},
        )
        db.add(msg)
        db.commit()
        result = msg.to_dict()
    except Exception as e:
        raise RuntimeError(f"Erro ao salvar mensagem: {e}")
    finally:
        if 'db' in locals():
            db.close()

    _update_session_updated_at(session_id)
    return result


def update_message(
    message_id: str,
    content: Optional[str] = None,
    metadata: Optional[Dict] = None
) -> Dict:
    db = get_sync_db()
    try:
        msg = db.query(Message).filter(Message.id == uuid_lib.UUID(message_id)).first()
        if not msg:
            raise RuntimeError(f"Mensagem {message_id} não encontrada")

        if content is not None:
            msg.content = content

        if metadata is not None:
            current_metadata = msg.metadata_ or {}
            current_metadata.update(metadata)
            msg.metadata_ = current_metadata

        db.commit()
        return msg.to_dict()
    except Exception as e:
        raise RuntimeError(f"Erro ao atualizar mensagem: {e}")
    finally:
        db.close()


def update_session_title(session_id: str, user_id: str, title: str) -> Dict:
    session = get_session(session_id, user_id)
    if not session:
        raise ValueError(f"Sessão {session_id} não encontrada ou não pertence ao usuário")

    db = get_sync_db()
    try:
        s = db.query(ChatSession).filter(ChatSession.id == uuid_lib.UUID(session_id)).first()
        if not s:
            raise ValueError(f"Sessão {session_id} não encontrada")
        s.title = title
        s.updated_at = datetime.now(timezone.utc)
        db.commit()
        return s.to_dict()
    except Exception as e:
        raise RuntimeError(f"Erro ao atualizar título: {e}")
    finally:
        db.close()


def _update_session_updated_at(session_id: str):
    db = get_sync_db()
    try:
        s = db.query(ChatSession).filter(ChatSession.id == uuid_lib.UUID(session_id)).first()
        if s:
            s.updated_at = datetime.now(timezone.utc)
            db.commit()
    except Exception as e:
        print(f"⚠️ Aviso: Erro ao atualizar updated_at da sessão {session_id}: {e}")
    finally:
        db.close()


def delete_session(session_id: str, user_id: str) -> bool:
    session = get_session(session_id, user_id)
    if not session:
        raise ValueError(f"Sessão {session_id} não encontrada ou não pertence ao usuário")

    db = get_sync_db()
    try:
        db.query(ChatSession).filter(
            ChatSession.id == uuid_lib.UUID(session_id),
            ChatSession.user_id == uuid_lib.UUID(user_id),
        ).delete()
        db.commit()
        return True
    except Exception as e:
        raise RuntimeError(f"Erro ao deletar sessão: {e}")
    finally:
        db.close()


def is_session_onboarding(session_id: str, user_id: str) -> bool:
    try:
        session = get_session(session_id, user_id)
        return session.get("is_onboarding", False) if session else False
    except Exception:
        return False


def insert_message(
    session_id: str,
    role: str,
    content: str,
    metadata: Optional[Dict] = None
) -> Dict:
    if role not in ['user', 'assistant', 'system']:
        raise ValueError(f"Role inválido: {role}. Deve ser 'user', 'assistant' ou 'system'")

    db = get_sync_db()
    try:
        msg = Message(
            session_id=uuid_lib.UUID(session_id),
            role=role,
            content=content,
            metadata_=metadata or {},
        )
        db.add(msg)
        db.commit()
        return msg.to_dict()
    except Exception as e:
        raise RuntimeError(f"Erro ao inserir mensagem: {e}")
    finally:
        db.close()
