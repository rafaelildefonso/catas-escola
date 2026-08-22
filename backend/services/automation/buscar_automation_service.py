from models.automation import Automation

class BuscarAutomationService:
    @staticmethod
    def executar(id):
        model = Automation.buscar_por_id(id)
        if not model:
            raise ValueError(f"Automation com id {id} nao encontrado")
        return model
