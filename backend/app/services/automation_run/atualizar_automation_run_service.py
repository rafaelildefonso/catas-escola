from app.models.automation_run import AutomationRun

class AtualizarAutomationRunService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = AutomationRun.buscar_por_id(id)
        if not model:
            raise ValueError(f"AutomationRun com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
