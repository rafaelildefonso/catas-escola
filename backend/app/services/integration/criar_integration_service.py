from app.models.integration import Integration

class CriarIntegrationService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = Integration(**dados)
        model.salvar()
        return model
