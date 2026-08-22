from models.user_webhook_config import UserWebhookConfig

class CriarUserWebhookConfigService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = UserWebhookConfig(**dados)
        model.salvar()
        return model
