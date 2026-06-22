# server/worker/modules/flow_modules.py
import asyncio
import logging
from worker.modules.registry import register_module

logger = logging.getLogger(__name__)

@register_module("flow.wait")
async def flow_wait(params: dict) -> dict:
    """
    Pausa a execução por um tempo determinado.
    Parâmetros:
      - duration: int | float — segundos a aguardar (obrigatório)
      - unit: str — 'seconds' (padrão), 'minutes'
    """
    duration = params.get("duration", 1)
    unit = params.get("unit", "seconds")

    if unit == "minutes":
        duration = duration * 60

    duration = max(0, float(duration))
    logger.info(f"⏳ [flow.wait] Aguardando {duration}s...")
    await asyncio.sleep(duration)
    logger.info(f"✅ [flow.wait] Pausa concluída ({duration}s).")
    return {"waited_seconds": duration}
