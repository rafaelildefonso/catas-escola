import logging
from typing import Any
from jinja2 import StrictUndefined, Template

logger = logging.getLogger(__name__)


def get_path_value(path_str: str, context: dict) -> Any:
    """
    Navega no contexto (dicionário) para extrair o valor de um path pontuado (ex: 'step_1.data.status').
    """
    parts = path_str.split(".")
    current = context
    for part in parts:
        if isinstance(current, dict) and part in current:
            current = current[part]
        elif hasattr(current, part):
            current = getattr(current, part)
        else:
            raise KeyError(
                f"Chave '{part}' não encontrada no caminho '{path_str}' do contexto."
            )
    return current


def resolve_variables(params: Any, context: dict) -> Any:
    """
    Percorre recursivamente um dicionário, lista ou string e resolve variáveis do contexto.
    Se o parâmetro for estritamente um placeholder '{{ step_id.campo }}', o valor é resolvido
    mantendo seu tipo original (ex: lista, dicionário, booleano, inteiro).
    Se for uma string combinada (ex: 'O email é {{ trigger.email }}'), é renderizado como string.
    """
    if isinstance(params, str):
        stripped = params.strip()
        # Se for estritamente um placeholder, preservamos o tipo original do objeto
        if stripped.startswith("{{") and stripped.endswith("}}"):
            expr = stripped[2:-2].strip()
            # Garante que seja um path de variável válido e não uma expressão complexa
            if "." in expr or expr.isalnum() or "_" in expr:
                try:
                    return get_path_value(expr, context)
                except Exception as e:
                    logger.debug(
                        f"Falha ao avaliar path direto '{expr}': {e}. Tentando Jinja2 genérico."
                    )
                    pass

        # Renderização padrão via Jinja2 para strings
        try:
            template = Template(params, undefined=StrictUndefined)
            # Renderiza no contexto
            rendered = template.render(**context)

            # Se for "True" ou "False" após renderização e a string original parecia um boolean,
            # ou parecia um número, podemos opcionalmente converter? Geralmente mantemos string,
            # mas o path direto acima já cobre 90% dos casos de tipagem.
            return rendered
        except Exception as e:
            logger.warning(f"Erro ao resolver uma informação da automação: {e}")
            raise ValueError(
                "Não foi possível obter uma informação necessária para executar esta etapa."
            ) from e

    elif isinstance(params, dict):
        return {k: resolve_variables(v, context) for k, v in params.items()}
    elif isinstance(params, list):
        return [resolve_variables(item, context) for item in params]
    else:
        return params
