"""
Worker HTTP server.
Recebe requisições de execução do catas_server, roda o AutomationRunner
e atualiza o resultado no Supabase.
"""
import asyncio
import logging
import traceback
from typing import Optional

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from pydantic import BaseModel

worker_app = FastAPI(title="CATAS Worker", version="0.1.0")
logger = logging.getLogger("worker.server")

_background_tasks: set = set()


class ExecuteRequest(BaseModel):
    automation_id: str
    plan: dict
    user_id: Optional[str] = None


async def _run_execution(automation_id: str, plan: dict, user_id: Optional[str]):
    from worker.runner import AutomationRunner
    from repositories import automations as automations_repo

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

        automations_repo.update_automation_run_status(
            automation_id,
            "completed",
            result_metadata={"run_context": result_context},
        )
        logger.info("✅ [Worker] Automação %s concluída com sucesso.", automation_id)

    except Exception as e:
        logger.error("❌ [Worker] Falha na automação %s: %s", automation_id, traceback.format_exc())
        try:
            automations_repo.update_automation_run_status(
                automation_id,
                "failed",
                error_details={"message": str(e), "traceback": traceback.format_exc()},
            )
        except Exception as db_err:
            logger.error("❌ [Worker] Falha ao atualizar status no DB: %s", db_err)


@worker_app.get("/health")
async def health():
    return {"status": "ok"}


@worker_app.post("/execute")
async def execute(req: ExecuteRequest):
    task = asyncio.create_task(_run_execution(
        req.automation_id, req.plan, req.user_id,
    ))
    _background_tasks.add(task)
    task.add_done_callback(_background_tasks.discard)

    logger.info(
        "📤 [Worker] Requisição aceita para automação %s. Executando em background.",
        req.automation_id,
    )
    return JSONResponse(
        status_code=202,
        content={"status": "accepted", "automation_id": req.automation_id},
    )
