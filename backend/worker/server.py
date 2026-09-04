"""
Worker HTTP server.
Recebe requisições de execução do catas_server, roda o AutomationRunner
e atualiza o resultado no banco de dados.
"""
import asyncio
import logging
import traceback
from typing import Optional

from flask import Flask, jsonify, request

worker_app = Flask(__name__)
logger = logging.getLogger("worker.server")

_background_tasks: set = set()


async def _run_execution(automation_id: str, plan: dict, user_id: Optional[str]):
    from worker.runner import AutomationRunner
    from worker.repositorio_dados import atualizar_status_run

    logger.info(
        "📥 [Worker] Executando automação %s (user=%s, steps=%s)",
        automation_id, user_id,
        [s.get("module_id") for s in plan.get("steps", [])],
    )

    try:
        runner = AutomationRunner()
        result_context = await runner.run_plan(
            plan,
            run_id=automation_id,
            user_id=user_id,
        )

        atualizar_status_run(
            automation_id,
            "completed",
            result_metadata={"run_context": result_context},
        )
        logger.info("✅ [Worker] Automação %s concluída com sucesso.", automation_id)

    except Exception as e:
        logger.error("❌ [Worker] Falha na automação %s: %s", automation_id, traceback.format_exc())
        try:
            atualizar_status_run(
                automation_id,
                "failed",
                error_details={"message": str(e), "traceback": traceback.format_exc()},
            )
        except Exception as db_err:
            logger.error("❌ [Worker] Falha ao atualizar status no DB: %s", db_err)


@worker_app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})


@worker_app.route("/execute", methods=["POST"])
def execute():
    data = request.get_json()
    automation_id = data["automation_id"]
    plan = data["plan"]
    user_id = data.get("user_id")

    task = asyncio.create_task(_run_execution(
        automation_id, plan, user_id,
    ))
    _background_tasks.add(task)
    task.add_done_callback(_background_tasks.discard)

    logger.info(
        "📤 [Worker] Requisição aceita para automação %s. Executando em background.",
        automation_id,
    )
    return jsonify({"status": "accepted", "automation_id": automation_id}), 202


if __name__ == "__main__":
    worker_app.run(host="0.0.0.0", port=8001, debug=False)
