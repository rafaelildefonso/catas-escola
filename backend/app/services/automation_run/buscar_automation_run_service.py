from app.models.automation_run import AutomationRun

class BuscarAutomationRunService:
    @staticmethod
    def executar(id):
        model = AutomationRun.buscar_por_id(id)
        if not model:
            raise ValueError(f"AutomationRun com id {id} nao encontrado")
        return model
