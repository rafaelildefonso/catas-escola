from datetime import date, datetime, timezone

from sqlalchemy import text

from extensions import db


def nome_dialeto() -> str:
    """Nome do dialeto do banco configurado (ex.: 'postgresql', 'sqlite')."""
    try:
        return db.session.get_bind().dialect.name or "sqlite"
    except Exception:
        return "sqlite"


def executar_procedure(nome: str, **parametros) -> list:
    """Chama procedure do banco (PostgreSQL): SELECT * FROM public.nome(args)."""
    cols = ", ".join(f":{k}" for k in parametros)
    stmt = text(f"SELECT * FROM public.{nome}({cols})")
    return executar(stmt, parametros)


def executar_linha(sql: str, **parametros) -> list:
    """Executa consulta inline (fallback para SQLite, onde nao ha procedures)."""
    return executar(text(sql), parametros)


def executar(stmt, parametros: dict) -> list:
    """Executa comando e devolve lista com dicts normalizados."""
    rows = db.session.execute(stmt, parametros).fetchall()
    return [normalizar_linha(r._mapping) for r in rows]


def normalizar_linhas(linhas: list) -> list:
    return [normalizar_linha(l) for l in linhas]


def normalizar_linha(mapping) -> dict:
    """Converte um mapping de linha em dict JSON-safe (datas → ISO)."""
    return {k: _valor(v) for k, v in mapping.items()}


def _valor(value):
    if isinstance(value, (datetime, date)):
        if isinstance(value, datetime) and value.tzinfo is not None:
            value = value.astimezone(timezone.utc).replace(tzinfo=None)
        return value.isoformat()
    return value