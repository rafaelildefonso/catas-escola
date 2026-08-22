from models.automation_generation_log import AutomationGenerationLog

class AtualizarAutomationGenerationLogService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = AutomationGenerationLog.buscar_por_id(id)
        if not model:
            raise ValueError(f"AutomationGenerationLog com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
