from app.models.message_feedback import MessageFeedback

class AtualizarMessageFeedbackService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = MessageFeedback.buscar_por_id(id)
        if not model:
            raise ValueError(f"MessageFeedback com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
