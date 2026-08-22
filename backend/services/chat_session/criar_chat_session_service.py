from models.chat_session import ChatSession

class CriarChatSessionService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = ChatSession(**dados)
        model.salvar()
        return model
