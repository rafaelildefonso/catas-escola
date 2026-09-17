import json
from datetime import datetime, timedelta, timezone

from sqlalchemy import text

from extensions import db
from repositories.base import executar_linha, executar_procedure, nome_dialeto


def relatorio_chat(user_id: str, dias: int = 30) -> dict:
    """Resumo de conversas/mensagens/feedback (JOIN chat_sessions ↔ messages).

    PostgreSQL: delega para a função public.fn_relatorio_chat.
    MySQL:      delega para a função fn_relatorio_chat.
    SQLite:     consulta inline equivalente (dev/teste).
    """
    if nome_dialeto() == "postgresql":
        value = db.session.execute(
            text("SELECT public.fn_relatorio_chat(:user_id, :dias)"),
            {"user_id": user_id, "dias": dias},
        ).scalar()
        if isinstance(value, str):
            value = json.loads(value)
        return value or {}

    if nome_dialeto() == "mysql":
        value = db.session.execute(
            text("SELECT fn_relatorio_chat(:user_id, :dias)"),
            {"user_id": user_id, "dias": dias},
        ).scalar()
        if isinstance(value, (dict, list)):
            return value or {}
        if isinstance(value, str):
            return json.loads(value) or {}
        return {}

    corte = (datetime.now(timezone.utc) - timedelta(days=dias)).strftime("%Y-%m-%d %H:%M:%S")
    base = """FROM messages m JOIN chat_sessions cs ON cs.id = m.session_id
              WHERE cs.user_id = :user_id AND m.created_at >= :corte"""
    params = {"user_id": user_id, "corte": corte}

    total_sessoes = _agregado(
        "SELECT COUNT(*) AS total FROM chat_sessions WHERE user_id = :user_id",
        {"user_id": user_id},
        "total",
    )
    total_mensagens = _agregado(
        f"SELECT COUNT(*) AS total {base}", params, "total"
    )
    sessoes_ativas = _agregado(
        f"SELECT COUNT(DISTINCT cs.id) AS total {base}", params, "total"
    )
    por_role = {
        r["role"]: r["total"]
        for r in executar_linha(
            f"SELECT m.role, COUNT(*) AS total {base} GROUP BY m.role", **params
        )
    }
    por_dia = executar_linha(
        f"""SELECT date(m.created_at) AS dia,
                   SUM(CASE WHEN m.role = 'user' THEN 1 ELSE 0 END) AS usuarios,
                   SUM(CASE WHEN m.role = 'assistant' THEN 1 ELSE 0 END) AS assistentes,
                   COUNT(*) AS total
            {base} GROUP BY date(m.created_at) ORDER BY dia""",
        **params,
    )
    feedback = _linha(
        """SELECT COALESCE(SUM(CASE WHEN is_liked = 1 THEN 1 ELSE 0 END), 0) AS likes,
                  COALESCE(SUM(CASE WHEN is_liked = 0 THEN 1 ELSE 0 END), 0) AS dislikes
           FROM message_feedback WHERE user_id = :user_id AND created_at >= :corte""",
        **params,
    )

    return {
        "total_sessoes": total_sessoes,
        "total_mensagens": total_mensagens,
        "sessoes_ativas": sessoes_ativas,
        "mensagens_por_role": por_role,
        "mensagens_por_dia": [
            {"dia": r["dia"], "usuarios": r["usuarios"], "assistentes": r["assistentes"]}
            for r in por_dia
        ],
        "feedback": {
            "likes": (feedback or {}).get("likes") or 0,
            "dislikes": (feedback or {}).get("dislikes") or 0,
        },
    }


def buscar_mensagens(user_id: str, termo: str, limite: int = 50, deslocamento: int = 0) -> dict:
    """Busca textual em mensagens do usuário (JOIN com sessões, ORDER BY data).

    PostgreSQL: delega para a função public.fn_buscar_mensagens.
    SQLite:     consulta direta equivalente (dev/teste).
    Retorna {"items": [...], "total": int}.
    """
    termo_limpo = (termo or "").strip()
    if not termo_limpo:
        return {"items": [], "total": 0}

    if nome_dialeto() in ("postgresql", "mysql"):
        linhas = executar_procedure(
            "fn_buscar_mensagens",
            user_id=user_id,
            termo=termo_limpo,
            limite=limite,
            deslocamento=deslocamento,
        )
        if not linhas:
            return {"items": [], "total": 0}
        total = linhas[0].get("total") or 0
        items = [{k: v for k, v in linha.items() if k != "total"} for linha in linhas]
        return {"items": items, "total": int(total)}

    params = {
        "user_id": user_id,
        "termo": f"%{termo_limpo}%",
        "limite": limite,
        "deslocamento": deslocamento,
    }
    total = executar_linha(
        """SELECT COUNT(*) AS total
           FROM messages m JOIN chat_sessions cs ON cs.id = m.session_id
           WHERE cs.user_id = :user_id AND (m.content LIKE :termo OR cs.title LIKE :termo)""",
        **params,
    )
    items = executar_linha(
        """SELECT m.id, m.session_id, cs.title AS session_title, m.role, m.content, m.created_at
           FROM messages m JOIN chat_sessions cs ON cs.id = m.session_id
           WHERE cs.user_id = :user_id AND (m.content LIKE :termo OR cs.title LIKE :termo)
           ORDER BY m.created_at DESC
           LIMIT :limite OFFSET :deslocamento""",
        **params,
    )
    return {"items": items, "total": int(total[0]["total"]) if total else 0}


def _linha(sql_inline: str, **params) -> dict | None:
    rows = executar_linha(sql_inline, **params)
    return rows[0] if rows else None


def _agregado(sql_inline: str, params: dict, coluna: str):
    linha = _linha(sql_inline, **params)
    if not linha:
        return 0
    return linha.get(coluna, 0)