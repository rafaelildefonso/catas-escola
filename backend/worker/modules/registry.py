import logging
from typing import Callable, Dict

logger = logging.getLogger(__name__)

# Catálogo global interno de módulos
_MODULE_REGISTRY: Dict[str, Callable] = {}

def register_module(module_id: str):
    """
    Decorador para registrar uma função assíncrona como módulo executável.
    Exemplo:
        @register_module("http.request")
        async def make_http_request(params: dict) -> dict:
            ...
    """
    def decorator(func: Callable):
        _MODULE_REGISTRY[module_id] = func
        logger.debug(f"Módulo registrado com sucesso: '{module_id}' -> '{func.__module__}.{func.__name__}'")
        return func
    return decorator

def get_module_function(module_id: str) -> Callable:
    """
    Recupera a função correspondente ao module_id. Retorna None caso não exista.
    """
    return _MODULE_REGISTRY.get(module_id)
