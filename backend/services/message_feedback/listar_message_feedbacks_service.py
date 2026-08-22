from models.message_feedback import MessageFeedback

class ListarMessageFeedbacksService:
    @staticmethod
    def executar():
        return MessageFeedback.listar_todos()
