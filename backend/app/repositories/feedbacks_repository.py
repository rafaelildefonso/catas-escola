from app.models.message_feedback import MessageFeedback


def buscar_por_mensagem_e_usuario(message_id: str, user_id: str):
    """Busca feedback existente pela chave lógica (message_id + user_id)."""
    return (
        MessageFeedback.query
        .filter(MessageFeedback.message_id == message_id, MessageFeedback.user_id == user_id)
        .first()
    )


def resumo_da_sessao(session_id: str) -> dict:
    """Agregação de likes/dislikes por sessão."""
    rows = (
        MessageFeedback.query
        .filter(MessageFeedback.session_id == session_id)
        .all()
    )
    likes = sum(1 for r in rows if r.is_liked is True)
    dislikes = sum(1 for r in rows if r.is_liked is False)
    return {"total": len(rows), "likes": likes, "dislikes": dislikes}
