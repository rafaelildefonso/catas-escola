from models.automation import Automation

class BuscarAutomationService:
    @staticmethod
    def executar(id, user_id=None):
        query = Automation.query.filter_by(id=id)
        if user_id is not None:
            query = query.filter_by(user_id=user_id)
        model = query.first()
        if not model:
            raise ValueError(f"Automation com id {id} nao encontrado")
        return model
