import asyncio
import threading
import traceback


class IniciarAutomacaoAssincronaService:
    """Dispara a execução da automação no Worker em uma thread separada.

    Em caso de falha imediata, marca a run como 'failed' com os detalhes do erro.
    """

    @staticmethod
    def executar(automation_id: str, plan: dict, user_id: str = None):
        from flask import current_app
        app = current_app._get_current_object()

        thread = threading.Thread(
            target=IniciarAutomacaoAssincronaService._executar_em_thread,
            args=(app, automation_id, plan, user_id),
            daemon=True,
        )
        thread.start()
        return automation_id

    @staticmethod
    def _executar_em_thread(app, automation_id: str, plan: dict, user_id: str = None):
        try:
            with app.app_context():
                from services.automacao.runner_service import AutomationRunnerService

                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                result = loop.run_until_complete(
                    AutomationRunnerService.start_automation(automation_id, plan, user_id=user_id)
                )

                from models.automation_run import AutomationRun
                run = AutomationRun.buscar_por_id(automation_id)
                if run:
                    run.atualizar(
                        execution_id=result["id"],
                        execution_run_id=result.get("first_execution_run_id"),
                    )
        except Exception as e:
            traceback.print_exc()
            try:
                with app.app_context():
                    from models.automation_run import AutomationRun
                    run = AutomationRun.buscar_por_id(automation_id)
                    if run:
                        run.atualizar(
                            status="failed",
                            error_details={
                                "message": str(e),
                                "traceback": traceback.format_exc(),
                            },
                        )
            except Exception:
                pass
