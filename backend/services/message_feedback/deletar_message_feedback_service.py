from models.message_feedback import MessageFeedback

class DeletarMessageFeedbackService:
    @staticmethod
    def executar(id):
        model = MessageFeedback.buscar_por_id(id)
        if not model:
            raise ValueError(f"MessageFeedback com id {id} nao encontrado")
        model.deletar()
        return None
