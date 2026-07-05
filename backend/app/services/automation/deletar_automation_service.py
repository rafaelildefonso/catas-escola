from app.models.automation import Automation

class DeletarAutomationService:
    @staticmethod
    def executar(id):
        model = Automation.buscar_por_id(id)
        if not model:
            raise ValueError(f"Automation com id {id} nao encontrado")
        model.deletar()
        return None
