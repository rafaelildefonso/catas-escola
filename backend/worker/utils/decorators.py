import asyncio
from functools import wraps
import logging

logger = logging.getLogger(__name__)

def async_retry(retries=3, delay=1.0, backoff=2.0, exceptions=(Exception,)):
    """
    Decorador assíncrono para retentativa de funções com exponential backoff.
    Ajuda a contornar falhas de rede em APIs externas (Gmail, HTTP Request, etc.) no MVP.
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            attempt = 0
            current_delay = delay
            while attempt < retries:
                try:
                    return await func(*args, **kwargs)
                except exceptions as e:
                    attempt += 1
                    if attempt >= retries:
                        logger.error(f"Função {func.__name__} falhou após {retries} tentativas: {e}")
                        raise
                    logger.warning(
                        f"Função {func.__name__} falhou (tentativa {attempt}/{retries}): {e}. "
                        f"Retentando em {current_delay}s..."
                    )
                    await asyncio.sleep(current_delay)
                    current_delay *= backoff
        return wrapper
    return decorator
