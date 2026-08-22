from models.integration import Integration

class DeletarIntegrationService:
    @staticmethod
    def executar(id):
        model = Integration.buscar_por_id(id)
        if not model:
            raise ValueError(f"Integration com id {id} nao encontrado")
        model.deletar()
        return None
