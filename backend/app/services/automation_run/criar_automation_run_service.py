from app.models.automation_run import AutomationRun

class CriarAutomationRunService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = AutomationRun(**dados)
        model.salvar()
        return model
