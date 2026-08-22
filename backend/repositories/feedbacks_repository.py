from models.message_feedback import MessageFeedback


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


def preferencias_do_usuario(user_id: str) -> dict:
    """Agrega reasons dos feedbacks do usuário em preferências positivas/negativas."""
    rows = (
        MessageFeedback.query
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
