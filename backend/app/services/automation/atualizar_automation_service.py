from app.models.automation import Automation

class AtualizarAutomationService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = Automation.buscar_por_id(id)
        if not model:
            raise ValueError(f"Automation com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
