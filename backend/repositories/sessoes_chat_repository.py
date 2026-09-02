from repositories.base import executar_linha
from extensions import db
from sqlalchemy import text


def listar_sessoes_do_usuario(user_id: str, limite: int = 50, deslocamento: int = 0) -> list:
    """Sessoes do usuario ordenadas pela atualizacao mais recente (filtro + paginacao)."""
    return executar_linha(
        """SELECT id, user_id, title, is_onboarding, created_at, updated_at
           FROM chat_sessions
           WHERE user_id = :user_id
           ORDER BY updated_at DESC
           LIMIT :limite OFFSET :deslocamento""",
        user_id=user_id,
        limite=limite,
        deslocamento=deslocamento,
    )


def buscar_sessao_do_usuario(session_id: str, user_id: str):
    """Busca a sessao garantindo que pertence ao usuario (filtro de posse)."""
    rows = executar_linha(
        """SELECT id, user_id, title, is_onboarding, created_at, updated_at
           FROM chat_sessions
           WHERE id = :session_id AND user_id = :user_id""",
        session_id=session_id,
        user_id=user_id,
    )
    return rows[0] if rows else None


def atualizar_sessao(session_id: str, user_id: str, **campos) -> dict | None:
    """Atualiza campos de uma sessao. Retorna a sessao atualizada."""
    if not campos:
        return buscar_sessao_do_usuario(session_id, user_id)

    sets = ", ".join(f"{k} = :{k}" for k in campos)
    params = {"session_id": session_id, "user_id": user_id, **campos}
    db.session.execute(
        text(f"UPDATE chat_sessions SET {sets} WHERE id = :session_id AND user_id = :user_id"),
        params,
    )
    db.session.commit()
    return buscar_sessao_do_usuario(session_id, user_id)


def deletar_sessao(session_id: str, user_id: str) -> bool:
    """Deleta uma sessao. Retorna True se algo foi deletado."""
    result = db.session.execute(
        text("DELETE FROM chat_sessions WHERE id = :session_id AND user_id = :user_id"),
        {"session_id": session_id, "user_id": user_id},
    )
    db.session.commit()
    return result.rowcount > 0


def listar_mensagens_da_sessao(session_id: str, limite: int = 100, deslocamento: int = 0) -> list:
    """Mensagens da sessao em ordem cronologica com paginacao."""
    return executar_linha(
        """SELECT id, session_id, role, content, metadata, created_at
           FROM messages
           WHERE session_id = :session_id
           ORDER BY created_at ASC
           LIMIT :limite OFFSET :deslocamento""",
        session_id=session_id,
        limite=limite,
        deslocamento=deslocamento,
    )
