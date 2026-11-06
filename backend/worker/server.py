"""
Worker HTTP server.
Recebe requisições de execução do catas_server, roda o AutomationRunner
e atualiza o resultado no banco de dados.
"""
import asyncio
import logging
import threading
import traceback
import hmac
import os
from typing import Optional

from flask import Flask, jsonify, request

worker_app = Flask(__name__)
logger = logging.getLogger("worker.server")


async def _run_execution(
    run_id: str,
    automation_id: Optional[str],
    plan: dict,
    user_id: Optional[str],
    trigger_payload=None,
):
    from worker.runner import AutomationRunner
    from worker.repositorio_dados import atualizar_status_run

    logger.info(
        "📥 [Worker] Executando automação %s (user=%s, steps=%s)",
        run_id, user_id,
        [s.get("module_id") for s in plan.get("steps", [])],
    )

    try:
        runner = AutomationRunner()
        result_context = await runner.run_plan(
            plan,
            run_id=run_id,
            automation_id=automation_id,
            user_id=user_id,
            trigger_payload=trigger_payload,
        )

        status_updated = atualizar_status_run(
            run_id,
            "completed",
            result_metadata={"run_context": result_context},
        )
        if status_updated is False:
            raise RuntimeError(f"Execução {run_id} não encontrada para atualizar o status")
        logger.info("✅ [Worker] Execução %s concluída com sucesso.", run_id)

    except Exception as e:
        logger.error("❌ [Worker] Falha na execução %s: %s", run_id, traceback.format_exc())
        try:
            atualizar_status_run(
                run_id,
                "failed",
                error_details={"message": str(e), "traceback": traceback.format_exc()},
            )
        except Exception as db_err:
            logger.error("❌ [Worker] Falha ao atualizar status no DB: %s", db_err)


@worker_app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})


def _run_in_thread(
    run_id: str,
    automation_id: Optional[str],
    plan: dict,
    user_id: Optional[str],
    trigger_payload=None,
):
    loop = asyncio.new_event_loop()
    try:
        loop.run_until_complete(
            _run_execution(run_id, automation_id, plan, user_id, trigger_payload)
        )
    finally:
        loop.close()


@worker_app.route("/execute", methods=["POST"])
def execute():
    secret = os.getenv("WORKER_SHARED_SECRET", "")
    if not secret and os.getenv("ENVIRONMENT", "development") != "development":
        return jsonify({"detail": "Worker não configurado"}), 503
    if secret and not hmac.compare_digest(request.headers.get("X-Worker-Secret", ""), secret):
        return jsonify({"detail": "Não autorizado"}), 401
    data = request.get_json()
    run_id = data.get("run_id")
    if not run_id:
        return jsonify({"detail": "run_id é obrigatório"}), 400

    automation_id = data.get("automation_id")
    plan = data["plan"]
    user_id = data.get("user_id")

    t = threading.Thread(
        target=_run_in_thread,
        args=(run_id, automation_id, plan, user_id, data.get("trigger_payload")),
        daemon=True,
    )
    t.start()

    logger.info(
        "📤 [Worker] Requisição aceita para execução %s. Executando em background.",
        run_id,
    )
    return jsonify({"status": "accepted", "run_id": run_id, "automation_id": automation_id}), 202


if __name__ == "__main__":
    worker_app.run(host="127.0.0.1", port=8001, debug=False)
