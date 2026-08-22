from typing import Optional

from models.automation_run import AutomationRun


class RegistrarAutomationRunService:
    """Cria ou atualiza (upsert) uma run de automação com status inicial 'running'.

    correlation_id recebe o próprio id da run (mesma semântica do fluxo legado).
    """

    @staticmethod
    def executar(
        run_id: str,
        user_id: str,
        *,
        status: str = "running",
        run_type: str = "direct",
        input_summary: Optional[str] = None,
        input_payload: Optional[dict] = None,
        result_metadata: Optional[dict] = None,
    ) -> AutomationRun:
        if not run_id or not user_id:
            raise ValueError("run_id e user_id sao obrigatorios")

        run = AutomationRun.buscar_por_id(run_id)
        if not run:
            run = AutomationRun(
                id=run_id,
                user_id=user_id,
                correlation_id=run_id,
                status=status,
                run_type=run_type,
                input_summary=input_summary or "",
                input_payload=input_payload or {},
                result_metadata=result_metadata or {},
            )
            run.salvar()
            return run

        run.atualizar(
            status=status,
            run_type=run_type,
            input_summary=input_summary or "",
            input_payload=input_payload or {},
            result_metadata=result_metadata or {},
        )
        return run
