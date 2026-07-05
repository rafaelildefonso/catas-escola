from app.models.automation_generation_log import AutomationGenerationLog

class ListarAutomationGenerationLogsService:
    @staticmethod
    def executar():
        return AutomationGenerationLog.listar_todos()
