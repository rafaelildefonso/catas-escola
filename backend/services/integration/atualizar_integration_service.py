from models.integration import Integration

class AtualizarIntegrationService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = Integration.buscar_por_id(id)
        if not model:
            raise ValueError(f"Integration com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
