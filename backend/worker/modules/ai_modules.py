import os
import json
import logging
from worker.utils.decorators import async_retry
from worker.modules.registry import register_module

logger = logging.getLogger(__name__)

# Configuração padrão caso AGENT_WORKER_TRANSFORM não esteja definida no .env
# Usa Groq/llama gratuito como fallback econômico
_DEFAULT_AGENT_CONFIG = "groq|llama-3.1-8b-instant|https://api.groq.com/openai/v1/chat/completions|GROQ_API_KEY"


def _get_provider():
    """
    Lê AGENT_WORKER_TRANSFORM do .env no formato 'provider|model|api_url|env_key_name'
    e retorna a instância do AIProvider via AIFactory (mesmo padrão do backend).
    """
    from services.ai_providers.factory import AIFactory

    config_str = os.getenv("AGENT_WORKER_TRANSFORM", _DEFAULT_AGENT_CONFIG)
    return AIFactory.create(config_str)


@register_module("ai.transform_data")
@async_retry(retries=3, delay=2.0, backoff=2.0)
async def ai_transform_data(params: dict) -> dict:
    """
    Processa, resume, formata ou extrai dados de textos usando o modelo
    definido em AGENT_WORKER_TRANSFORM no .env.

    Parâmetros aceitos:
      - input_text (ou text): str — texto a processar (obrigatório)
      - instruction: str — instrução do que fazer com o texto
      - format: str — 'text' (padrão) ou 'json'
    """
    input_text = params.get("input_text", params.get("text", ""))
    instruction = params.get("instruction", "Resuma o texto fornecido.")
    out_format = params.get("format", "text").lower()

    if not input_text:
        raise ValueError(
            "O parâmetro 'input_text' ou 'text' é obrigatório no módulo 'ai.transform_data'."
        )

    system_prompt = "Você é um assistente de automação especialista em extração e transformação de dados."
    user_content = f"Instrução: {instruction}\n\nTexto de Entrada:\n{input_text}"

    if out_format == "json":
        user_content += (
            "\n\nRetorne a resposta estritamente no formato JSON válido. "
            "Não inclua explicações ou formatação além do JSON."
        )

    logger.info(
        f"🤖 [ai.transform_data] Modelo: {os.getenv('AGENT_WORKER_TRANSFORM', _DEFAULT_AGENT_CONFIG).split('|')[1]} "
        f"| Instrução: '{instruction[:60]}'"
    )

    try:
        provider = _get_provider()
        response_mime = "application/json" if out_format == "json" else "text/plain"

        result = await provider.generate_response(
            system_prompt=system_prompt,
            user_content=user_content,
            temperature=0.1,
            response_mime_type=response_mime,
        )
        result_text = result.get("raw_text", "").strip()

    except Exception as e:
        logger.error(f"❌ [ai.transform_data] Falha no provider: {e}. Usando Mock local.")
        result_text = None

    # Mock Fallback — garante que o fluxo nunca trava sem chaves de API
    if not result_text:
        logger.warning("⚠️ [ai.transform_data] Retornando Mock local (sem chave de API ou erro).")
        if out_format == "json":
            result_text = json.dumps({
                "status": "mock",
                "instruction": instruction,
                "input_length": len(input_text),
                "summary": f"Mock sobre: '{input_text[:40]}'"
            })
        else:
            result_text = (
                f"[Resposta MOCK]\nInstrução: {instruction}\n"
                f"Texto (trecho): {input_text[:60]}..."
            )

    # Se o formato esperado for JSON, tenta parsear e limpar blocos markdown
    if out_format == "json":
        try:
            cleaned = result_text.strip()
            if cleaned.startswith("```json"):
                cleaned = cleaned[7:]
            elif cleaned.startswith("```"):
                cleaned = cleaned[3:]
            if cleaned.endswith("```"):
                cleaned = cleaned[:-3]
            cleaned = cleaned.strip()

            return {"text": result_text, "parsed": json.loads(cleaned)}
        except Exception:
            logger.warning("⚠️ [ai.transform_data] IA retornou JSON inválido. Retornando texto bruto.")

    return {"text": result_text}
