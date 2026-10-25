from models.automation import Automation

class CriarAutomationService:
    @staticmethod
    def executar(dados, user_id=None):
        from services.automation.validation import validate_automation_data

        campos = validate_automation_data(dados, creating=True)
        if user_id is not None:
            campos["user_id"] = user_id
        elif dados.get("user_id"):
            campos["user_id"] = dados["user_id"]
        else:
            raise ValueError("Usuário é obrigatório")
        model = Automation(**campos)
        model.salvar()
        return model
