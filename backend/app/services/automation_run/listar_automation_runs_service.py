from app.models.automation_run import AutomationRun

class ListarAutomationRunsService:
    @staticmethod
    def executar():
        return AutomationRun.listar_todos()
