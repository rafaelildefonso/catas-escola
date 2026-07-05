from app.models.user_webhook_config import UserWebhookConfig

class AtualizarUserWebhookConfigService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = UserWebhookConfig.buscar_por_id(id)
        if not model:
            raise ValueError(f"UserWebhookConfig com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
