from models.automation import Automation

class DeletarAutomationService:
    @staticmethod
    def executar(id, user_id=None):
        from services.automation.buscar_automation_service import BuscarAutomationService

        model: Automation = BuscarAutomationService.executar(id, user_id)
        model.deletar()
        return None
