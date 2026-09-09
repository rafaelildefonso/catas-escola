from models.automation_step_log import AutomationStepLog

class ListarAutomationStepLogsService:
    @staticmethod
    def executar(automation_id=None, run_id=None):
        return AutomationStepLog.listar_todos(automation_id=automation_id, run_id=run_id)
