import os
import uuid
import logging
from typing import Any, Dict

import httpx

logger = logging.getLogger(__name__)

WORKER_URL = os.getenv("WORKER_URL", "http://localhost:8001")
WORKER_SHARED_SECRET = os.getenv("WORKER_SHARED_SECRET", "")


class AutomationRunnerService:
    """
    Serviço de execução de automações — MVP sem Temporal.
    Envia a execução para o worker HTTP (catas_worker).
    Se o worker não responder, a automação falha com erro claro.
    """

    @classmethod
    async def start_automation(
        cls,
        automation_id: str,
        plan: dict,
        user_id: str = None,
    ):
        logger.info("🚀 Disparando execução para run_id: %s", automation_id)

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.post(
                    f"{WORKER_URL}/execute",
                    json={
                        "automation_id": automation_id,
                        "plan": plan,
                        "user_id": user_id,
                    },
                    headers={"X-Worker-Secret": WORKER_SHARED_SECRET},
                )
                if resp.status_code != 202:
                    raise RuntimeError(f"Worker rejeitou execução {automation_id}: HTTP {resp.status_code}")
                logger.info("Worker aceitou execução %s", automation_id)

        except Exception as e:
            logger.error(
                "❌ Worker não disponível (%s). A automação %s NÃO será executada.",
                e, automation_id,
            )
            raise

        return {
            "id": f"direct-{automation_id}",
            "first_execution_run_id": f"direct-{automation_id}",
        }

    @classmethod
    async def trigger_automation_from_webhook(
        cls,
        automation_id: str,
        plan: Dict[str, Any],
        webhook_payload: Dict[str, Any],
        user_id: str = None,
    ):
        plan.setdefault("context", {})
        plan["context"]["webhook_payload"] = webhook_payload

        unique_run_id = f"webhook-{automation_id}-{uuid.uuid4().hex[:8]}"
        logger.info("🔗 [Webhook] Disparando execução: %s", unique_run_id)

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.post(
                    f"{WORKER_URL}/execute",
                    json={
                        "automation_id": unique_run_id,
                        "plan": plan,
                        "user_id": user_id,
                    },
                    headers={"X-Worker-Secret": WORKER_SHARED_SECRET},
                )
                if resp.status_code == 202:
                    logger.info("✅ Worker aceitou webhook %s", unique_run_id)
                else:
                    raise RuntimeError(f"Worker rejeitou webhook {unique_run_id}: HTTP {resp.status_code}")
        except Exception as e:
            logger.error(
                "❌ Worker não disponível para webhook (%s). Webhook %s NÃO será executado.",
                e, unique_run_id,
            )
            raise

        return {
            "id": unique_run_id,
            "first_execution_run_id": unique_run_id,
        }
