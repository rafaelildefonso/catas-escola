from app.models.automation import Automation

class CriarAutomationService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = Automation(**dados)
        model.salvar()
        return model
