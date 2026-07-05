from app.models.user_webhook_config import UserWebhookConfig

class BuscarUserWebhookConfigService:
    @staticmethod
    def executar(id):
        model = UserWebhookConfig.buscar_por_id(id)
        if not model:
            raise ValueError(f"UserWebhookConfig com id {id} nao encontrado")
        return model
