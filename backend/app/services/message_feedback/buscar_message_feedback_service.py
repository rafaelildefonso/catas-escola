from app.models.message_feedback import MessageFeedback

class BuscarMessageFeedbackService:
    @staticmethod
    def executar(id):
        model = MessageFeedback.buscar_por_id(id)
        if not model:
            raise ValueError(f"MessageFeedback com id {id} nao encontrado")
        return model
