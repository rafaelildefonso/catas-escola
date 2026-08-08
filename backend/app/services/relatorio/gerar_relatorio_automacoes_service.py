from app.repositories.automacao_repository import listar_runs_filtrados

_STATUS_VALIDOS = {"pending", "running", "paused", "completed", "failed", "canceled"}
_ORDENACOES_VALIDAS = {"created_at", "updated_at", "started_at", "status", "run_type"}


class GerarRelatorioAutomacoesService:
    """Caso de uso: relatório paginado de execuções de automação."""

    @staticmethod
    def executar(
        user_id: str,
        status=None,
        data_inicio=None,
        data_fim=None,
        busca=None,
        ordem="created_at",
        limite=50,
        deslocamento=0,
    ) -> dict:
        if not user_id:
            raise ValueError("user_id e obrigatorio")
        if status and status not in _STATUS_VALIDOS:
            raise ValueError(f"status invalido: {status}")
        if busca and len(busca.strip()) < 2:
            raise ValueError("busca deve ter pelo menos 2 caracteres")
        if ordem not in _ORDENACOES_VALIDAS:
            ordem = "created_at"

        data_inicio = _normalizar_inicio(data_inicio)
        data_fim = _normalizar_fim(data_fim)
        limite = _limitar(limite, minimo=1, maximo=100, padrao=50)
        deslocamento = _limitar(deslocamento, minimo=0, maximo=None, padrao=0)

        return listar_runs_filtrados(
            user_id=user_id,
            status=status,
            data_inicio=data_inicio,
            data_fim=data_fim,
            busca=busca,
            ordem=ordem,
            limite=limite,
            deslocamento=deslocamento,
        )


def _normalizar_inicio(valor):
    if not valor or valor in ("null", "None"):
        return None
    return valor.strip()


def _normalizar_fim(valor):
    if not valor or valor in ("null", "None"):
        return None
    valor = valor.strip()
    if len(valor) == 10:
        valor += " 23:59:59"
    return valor


def _limitar(valor, minimo, maximo, padrao):
    try:
        inteiro = int(valor)
    except (TypeError, ValueError):
        return padrao
    inteiro = max(inteiro, minimo)
    if maximo is not None:
        inteiro = min(inteiro, maximo)
    return inteiro