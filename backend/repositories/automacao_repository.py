from repositories.base import executar_linha, executar_procedure, nome_dialeto

# Colunas aceitas para ordenação (whitelist — evita injeção via ORDER BY dinâmico)
_ORDENACOES = {
    "created_at": "ar.created_at",
    "updated_at": "ar.updated_at",
    "started_at": "ar.started_at",
    "status": "ar.status",
    "run_type": "ar.run_type",
}


def listar_runs_filtrados(
    user_id: str,
    status: str | None = None,
    data_inicio: str | None = None,
    data_fim: str | None = None,
    busca: str | None = None,
    ordem: str = "created_at",
    limite: int = 50,
    deslocamento: int = 0,
) -> dict:
    """Relatório paginado de execuções de automação com JOIN na definição.

    PostgreSQL: delega para a função public.fn_relatorio_automacoes.
    SQLite:     executa consulta inline equivalente (dev/teste).

    Retorna {"items": [...], "total": int}.
    """
    busca = (busca or "").strip() or None
    ordem = ordem if ordem in _ORDENACOES else "created_at"

    if nome_dialeto() == "postgresql":
        linhas = executar_procedure(
            "fn_relatorio_automacoes",
            user_id=user_id,
            status=status,
            data_inicio=_dtou(data_inicio),
            data_fim=_dtou(data_fim),
            busca=busca,
            ordem=ordem,
            limite=limite,
            deslocamento=deslocamento,
        )
        return _agrupar(linhas)

    clausulas = ["ar.user_id = :user_id"]
    params = {"user_id": user_id}

    if status:
        clausulas.append("ar.status = :status")
        params["status"] = status
    if data_inicio:
        clausulas.append("ar.created_at >= :data_inicio")
        params["data_inicio"] = data_inicio
    if data_fim:
        clausulas.append("ar.created_at <= :data_fim")
        params["data_fim"] = data_fim
    if busca:
        clausulas.append(
            "(ar.input_summary LIKE :busca OR a.name LIKE :busca OR a.description LIKE :busca)"
        )
        params["busca"] = f"%{busca}%"

    where = " AND ".join(clausulas)
    params["ordem"] = _ORDENACOES[ordem]
    params["limite"] = limite
    params["deslocamento"] = deslocamento

    total_rows = executar_linha(
        f"""SELECT COUNT(*) AS total
            FROM automation_runs ar
            LEFT JOIN automations a ON a.id = ar.automation_id
            WHERE {where}""",
        **params,
    )
    items = executar_linha(
        f"""SELECT ar.id, ar.user_id, ar.automation_id, a.name AS automation_name,
                   ar.status, ar.run_type, ar.input_summary,
                   ar.created_at, ar.started_at, ar.finished_at
            FROM automation_runs ar
            LEFT JOIN automations a ON a.id = ar.automation_id
            WHERE {where}
            ORDER BY {params['ordem']} ASC, ar.created_at DESC
            LIMIT :limite OFFSET :deslocamento""",
        **params,
    )
    return {
        "items": items,
        "total": int(total_rows[0]["total"]) if total_rows else 0,
    }


def _agrupar(linhas: list) -> dict:
    if not linhas:
        return {"items": [], "total": 0}
    total = linhas[0].get("total") or 0
    items = [{k: v for k, v in linha.items() if k != "total"} for linha in linhas]
    return {"items": items, "total": int(total)}


def _dtou(data: str | None):
    """Converte string ISO de data/hora (ou None) para as procedures."""
    if not data or data in ("null", "None"):
        return None
    return data.replace(" 23:59:59", "T23:59:59")