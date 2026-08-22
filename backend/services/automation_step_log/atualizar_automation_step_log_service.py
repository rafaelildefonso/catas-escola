from models.automation_step_log import AutomationStepLog

class AtualizarAutomationStepLogService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = AutomationStepLog.buscar_por_id(id)
        if not model:
            raise ValueError(f"AutomationStepLog com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
