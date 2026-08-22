from models.automation_generation_log import AutomationGenerationLog

class BuscarAutomationGenerationLogService:
    @staticmethod
    def executar(id):
        model = AutomationGenerationLog.buscar_por_id(id)
        if not model:
            raise ValueError(f"AutomationGenerationLog com id {id} nao encontrado")
        return model
