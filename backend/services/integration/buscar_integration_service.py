from models.integration import Integration

class BuscarIntegrationService:
    @staticmethod
    def executar(id, user_id):
        model = Integration.query.filter_by(id=id, user_id=user_id).first()
        if not model:
            raise ValueError(f"Integration com id {id} nao encontrado")
        return model
