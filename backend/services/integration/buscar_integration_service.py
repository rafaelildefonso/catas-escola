from models.integration import Integration

class BuscarIntegrationService:
    @staticmethod
    def executar(id):
        model = Integration.buscar_por_id(id)
        if not model:
            raise ValueError(f"Integration com id {id} nao encontrado")
        return model
