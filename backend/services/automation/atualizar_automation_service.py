from models.automation import Automation

class AtualizarAutomationService:
    @staticmethod
    def executar(id, dados, user_id=None) -> Automation:
        from services.automation.validation import validate_automation_data
        from services.automation.buscar_automation_service import BuscarAutomationService

        model = BuscarAutomationService.executar(id, user_id)
        campos = validate_automation_data(dados, existing=model)
        model.atualizar(**campos)
        return model
