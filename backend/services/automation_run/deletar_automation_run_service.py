from models.automation_run import AutomationRun

class DeletarAutomationRunService:
    @staticmethod
    def executar(id):
        model = AutomationRun.buscar_por_id(id)
        if not model:
            raise ValueError(f"AutomationRun com id {id} nao encontrado")
        model.deletar()
        return None
