from models.automation import Automation

class ListarAutomationsService:
    @staticmethod
    def executar(user_id=None, status=None):
        query = Automation.query
        if user_id is not None:
            query = query.filter_by(user_id=user_id)
        if status is not None:
            if status not in {"draft", "active", "paused"}:
                raise ValueError("Status inválido")
            query = query.filter_by(status=status)
        return query.order_by(Automation.created_at.desc()).all()
