from models.automation_generation_log import AutomationGenerationLog

class CriarAutomationGenerationLogService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = AutomationGenerationLog(**dados)
        model.salvar()
        return model
