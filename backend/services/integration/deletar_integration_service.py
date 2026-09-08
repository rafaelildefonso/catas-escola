from models.integration import Integration

class DeletarIntegrationService:
    @staticmethod
    def executar(id):
        model = Integration.buscar_por_id(id)
        if not model:
            raise ValueError(f"Integration com id {id} nao encontrado")
        model.deletar()
        return None

    @staticmethod
    def executar_por_provider(user_id, provider):
        model = Integration.query.filter_by(user_id=user_id, provider=provider).first()
        if not model:
            raise ValueError(f"Integration {provider} nao encontrada para o usuario")
        model.deletar()
        return None
