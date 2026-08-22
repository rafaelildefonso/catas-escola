from models.chat_session import ChatSession

class BuscarChatSessionService:
    @staticmethod
    def executar(id):
        model = ChatSession.buscar_por_id(id)
        if not model:
            raise ValueError(f"ChatSession com id {id} nao encontrado")
        return model
