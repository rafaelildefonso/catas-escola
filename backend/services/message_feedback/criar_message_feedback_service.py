from models.message_feedback import MessageFeedback

class CriarMessageFeedbackService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = MessageFeedback(**dados)
        model.salvar()
        return model
