from models.integration import Integration

class ListarIntegrationsService:
    @staticmethod
    def executar(user_id=None):
        if user_id:
            return Integration.query.filter_by(user_id=user_id).all()
        return Integration.listar_todos()
