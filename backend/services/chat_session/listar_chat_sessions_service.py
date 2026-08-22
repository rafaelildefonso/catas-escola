from models.chat_session import ChatSession

class ListarChatSessionsService:
    @staticmethod
    def executar():
        return ChatSession.listar_todos()
