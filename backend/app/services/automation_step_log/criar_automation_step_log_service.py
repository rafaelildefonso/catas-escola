from app.models.automation_step_log import AutomationStepLog

class CriarAutomationStepLogService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = AutomationStepLog(**dados)
        model.salvar()
        return model
