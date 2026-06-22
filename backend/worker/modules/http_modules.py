import httpx
import logging
from worker.utils.decorators import async_retry
from worker.modules.registry import register_module

logger = logging.getLogger(__name__)

@register_module("http.request")
@async_retry(retries=3, delay=1.0, backoff=2.0, exceptions=(httpx.HTTPError, httpx.NetworkError, httpx.TimeoutException))
async def make_http_request(params: dict) -> dict:
    """
    Módulo genérico de requisição HTTP (REST).
    Parâmetros aceitos:
      - method: str (padrão GET)
      - url: str (obrigatório)
      - headers: dict (opcional)
      - json: dict/list (opcional) ou body: dict/list (opcional)
      - query_params: dict (opcional)
    """
    method = params.get("method", "GET").upper()
    url = params.get("url")
    headers = params.get("headers", {})
    json_data = params.get("json", params.get("body"))
    query_params = params.get("query_params", params.get("params"))
    
    if not url:
        raise ValueError("O parâmetro 'url' é obrigatório no módulo 'http.request'.")
        
    logger.info(f"🌐 Enviando requisição HTTP: {method} {url}")
    
    async with httpx.AsyncClient() as client:
        response = await client.request(
            method=method,
            url=url,
            headers=headers,
            json=json_data,
            params=query_params,
            timeout=30.0
        )
        
        # Dispara exceção para status codes de erro (4xx/5xx) para acionar o retry decorator
        response.raise_for_status()
        
        try:
            data = response.json()
        except ValueError:
            data = response.text
            
        logger.info(f"📥 Resposta HTTP recebida: {response.status_code}")
        
        return {
            "status_code": response.status_code,
            "data": data,
            "headers": dict(response.headers)
        }
