# worker/main.py — Entry point standalone para debug/teste local
# Executa o AutomationRunner diretamente (sem Temporal)
import asyncio
import json
import logging
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from dotenv import load_dotenv

from worker.runner import AutomationRunner
import worker.modules  # noqa: F401  # Registra todos os módulos no catálogo

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
)
logger = logging.getLogger(__name__)


def load_plan_from_args() -> dict | None:
    if len(sys.argv) < 2:
        return None
    path = sys.argv[1]
    if not os.path.isfile(path):
        logger.error("Arquivo não encontrado: %s", path)
        return None
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


async def main():
    plan = load_plan_from_args()
    if plan is None:
        logger.info(
            "Nenhum plano fornecido. Uso: python -m worker.main <plan.json>\n"
            "Executando plano de exemplo embutido..."
        )
        plan = {
            "name": "Exemplo — Hello World",
            "steps": [
                {
                    "step_id": "saudacao",
                    "module_id": "http.request",
                    "params": {
                        "url": "https://httpbin.org/uuid",
                        "method": "GET",
                    },
                },
                {
                    "step_id": "transformar",
                    "module_id": "ai.transform_data",
                    "params": {
                        "input_text": "{{saudacao.data.uuid}}",
                        "instruction": "Retorne APENAS o UUID, sem mais texto.",
                    },
                },
            ],
        }

    logger.info("🚀 Executando plano: %s", plan.get("name", "Sem nome"))
    runner = AutomationRunner()
    try:
        result = await runner.run_plan(plan)
        logger.info("✅ Resultado final:\n%s", json.dumps(result, indent=2, ensure_ascii=False))
    except Exception as e:
        logger.error("❌ Plano falhou: %s", e)


if __name__ == "__main__":
    asyncio.run(main())
