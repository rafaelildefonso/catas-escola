from app.models.user_webhook_config import UserWebhookConfig

class ListarUserWebhookConfigsService:
    @staticmethod
    def executar():
        return UserWebhookConfig.listar_todos()
