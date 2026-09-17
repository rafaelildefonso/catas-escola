import json
from datetime import datetime, timedelta, timezone

from sqlalchemy import text

from extensions import db
from repositories.base import executar_linha, nome_dialeto


def estatisticas_dashboard(user_id: str, dias: int = 7) -> dict:
    """Estatísticas agregadas do dashboard do usuário.

    PostgreSQL: delega para a procedure public.fn_dashboard_estatisticas.
    MySQL:      delega para a função fn_dashboard_estatisticas.
    SQLite:     consulta inline equivalente (dev/teste).
    """
    if nome_dialeto() == "postgresql":
        value = db.session.execute(
            text("SELECT public.fn_dashboard_estatisticas(:user_id, :dias)"),
            {"user_id": user_id, "dias": dias},
        ).scalar()
        if isinstance(value, str):
            value = json.loads(value)
        return value or {}

    if nome_dialeto() == "mysql":
        value = db.session.execute(
            text("SELECT fn_dashboard_estatisticas(:user_id, :dias)"),
            {"user_id": user_id, "dias": dias},
        ).scalar()
        if isinstance(value, (dict, list)):
            return value or {}
        if isinstance(value, str):
            return json.loads(value) or {}
        return {}

    corte = (datetime.now(timezone.utc) - timedelta(days=dias)).strftime("%Y-%m-%d %H:%M:%S")
    params = {"user_id": user_id, "corte": corte}

    total_execucoes = _agregado(
        "SELECT COUNT(*) AS total FROM automation_runs WHERE user_id = :user_id AND created_at >= :corte",
        params,
        "total",
    )
    taxa = _agregado(
        """SELECT CASE WHEN COUNT(*) = 0 THEN 0 ELSE
                 ROUND(100.0 * SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) / COUNT(*)) END AS taxa
           FROM automation_runs WHERE user_id = :user_id AND created_at >= :corte""",
        params,
        "taxa",
    )
    duracao = _agregado(
        _sql_duracao_media(),
        params,
        "seg",
    )

    por_status = executar_linha(
        "SELECT status, COUNT(*) AS total FROM automation_runs WHERE user_id = :user_id AND created_at >= :corte GROUP BY status",
        **params,
    )
    por_dia = executar_linha(
        "SELECT date(created_at) AS dia, COUNT(*) AS total FROM automation_runs WHERE user_id = :user_id AND created_at >= :corte GROUP BY date(created_at) ORDER BY dia",
        **params,
    )
    top_integracoes = executar_linha(
        "SELECT provider, COUNT(*) AS total FROM integrations WHERE user_id = :user_id GROUP BY provider ORDER BY total DESC LIMIT 5",
        user_id=user_id,
    )

    total_sessoes = _agregado(
        "SELECT COUNT(*) AS total FROM chat_sessions WHERE user_id = :user_id",
        {"user_id": user_id},
        "total",
    )
    total_mensagens = _agregado(
        """SELECT COUNT(*) AS total FROM messages m
           JOIN chat_sessions cs ON cs.id = m.session_id
           WHERE cs.user_id = :user_id""",
        {"user_id": user_id},
        "total",
    )

    return {
        "total_execucoes": total_execucoes,
        "taxa_sucesso": int(taxa or 0),
        "duracao_media_segundos": float(duracao or 0),
        "execucoes_por_status": {r["status"]: r["total"] for r in por_status},
        "execucoes_por_dia": [{"dia": r["dia"], "total": r["total"]} for r in por_dia],
        "top_integracoes": [{"provider": r["provider"], "total": r["total"]} for r in top_integracoes],
        "total_sessoes_chat": total_sessoes,
        "total_mensagens_chat": total_mensagens,
    }


def _agregado(sql_inline: str, params: dict, coluna: str):
    rows = executar_linha(sql_inline, **params)
    if not rows:
        return 0
    return rows[0].get(coluna, 0)


def _sql_duracao_media() -> str:
    """Expressão de duração média por dialeto (MySQL usa TIMESTAMPDIFF)."""
    if nome_dialeto() == "mysql":
        return (
            "SELECT CASE WHEN COUNT(*) = 0 THEN 0 ELSE "
            "ROUND(AVG(TIMESTAMPDIFF(SECOND, started_at, finished_at)), 0) END AS seg "
            "FROM automation_runs "
            "WHERE user_id = :user_id AND created_at >= :corte AND finished_at IS NOT NULL"
        )
    return (
        "SELECT COALESCE(ROUND(AVG((julianday(finished_at) - julianday(started_at)) * 86400.0), 1), 0) AS seg "
        "FROM automation_runs "
        "WHERE user_id = :user_id AND created_at >= :corte AND finished_at IS NOT NULL"
    )