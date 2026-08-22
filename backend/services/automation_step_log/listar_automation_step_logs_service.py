from models.automation_step_log import AutomationStepLog

class ListarAutomationStepLogsService:
    @staticmethod
    def executar():
        return AutomationStepLog.listar_todos()
