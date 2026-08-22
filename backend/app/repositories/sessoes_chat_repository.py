from app.extensions import db
from app.models.chat_session import ChatSession
from app.models.message import Message


def listar_sessoes_do_usuario(user_id: str, limite: int = 50, deslocamento: int = 0) -> list:
    """Sessões do usuário ordenadas pela atualização mais recente (filtro + paginação)."""
    query = (
        ChatSession.query
        .filter(ChatSession.user_id == user_id)
        .order_by(ChatSession.updated_at.desc())
        .offset(deslocamento)
        .limit(limite)
    )
    return [s.to_dict() for s in query.all()]


def buscar_sessao_do_usuario(session_id: str, user_id: str):
    """Busca a sessão garantindo que pertence ao usuário (filtro de posse)."""
    return (
        ChatSession.query
        .filter(ChatSession.id == session_id, ChatSession.user_id == user_id)
        .first()
    )


def listar_mensagens_da_sessao(session_id: str, limite: int = 100, deslocamento: int = 0) -> list:
    """Mensagens da sessão em ordem cronológica com paginação."""
    query = (
        Message.query
        .filter(Message.session_id == session_id)
        .order_by(Message.created_at.asc())
        .offset(deslocamento)
        .limit(limite)
    )
    return [m.to_dict() for m in query.all()]
