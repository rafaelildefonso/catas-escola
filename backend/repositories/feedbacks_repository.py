from repositories.base import executar_linha
from extensions import db
from sqlalchemy import text


def buscar_por_mensagem_e_usuario(message_id: str, user_id: str):
    """Busca feedback existente pela chave logica (message_id + user_id)."""
    rows = executar_linha(
        """SELECT id, message_id, user_id, session_id, is_liked, reason, created_at, updated_at
           FROM message_feedback
           WHERE message_id = :message_id AND user_id = :user_id""",
        message_id=message_id,
        user_id=user_id,
    )
    return rows[0] if rows else None


def atualizar_por_mensagem_e_usuario(message_id: str, user_id: str, **campos) -> dict | None:
    """Atualiza feedback existente pela chave logica. Retorna o registro atualizado."""
    if not campos:
        return buscar_por_mensagem_e_usuario(message_id, user_id)

    sets = ", ".join(f"{k} = :{k}" for k in campos)
    params = {"message_id": message_id, "user_id": user_id, **campos}
    db.session.execute(
        text(f"UPDATE message_feedback SET {sets} WHERE message_id = :message_id AND user_id = :user_id"),
        params,
    )
    db.session.commit()
    return buscar_por_mensagem_e_usuario(message_id, user_id)


def deletar_por_mensagem_e_usuario(message_id: str, user_id: str) -> bool:
    """Deleta feedback pela chave logica. Retorna True se algo foi deletado."""
    result = db.session.execute(
        text("DELETE FROM message_feedback WHERE message_id = :message_id AND user_id = :user_id"),
        {"message_id": message_id, "user_id": user_id},
    )
    db.session.commit()
    return result.rowcount > 0


def resumo_da_sessao(session_id: str) -> dict:
    """Agregacao de likes/dislikes por sessao."""
    rows = executar_linha(
        """SELECT
               COUNT(*) AS total,
               SUM(CASE WHEN is_liked = 1 THEN 1 ELSE 0 END) AS likes,
               SUM(CASE WHEN is_liked = 0 THEN 1 ELSE 0 END) AS dislikes
           FROM message_feedback
           WHERE session_id = :session_id""",
        session_id=session_id,
    )
    row = rows[0] if rows else {}
    return {
        "total": row.get("total") or 0,
        "likes": row.get("likes") or 0,
        "dislikes": row.get("dislikes") or 0,
    }


def preferencias_do_usuario(user_id: str) -> dict:
    """Agrega reasons dos feedbacks do usuario em preferencias positivas/negativas."""
    rows = executar_linha(
        """SELECT reason, is_liked, COUNT(*) AS cnt
           FROM message_feedback
           WHERE user_id = :user_id AND reason IS NOT NULL
           GROUP BY reason, is_liked""",
        user_id=user_id,
    )
    positive_reasons = {}
    negative_reasons = {}
    total = 0

    for row in rows:
        cnt = row["cnt"]
        total += cnt
        if row["is_liked"] is True:
            positive_reasons[row["reason"]] = positive_reasons.get(row["reason"], 0) + cnt
        elif row["is_liked"] is False:
            negative_reasons[row["reason"]] = negative_reasons.get(row["reason"], 0) + cnt

    return {
        "positive": positive_reasons,
        "negative": negative_reasons,
        "total": total,
    }
