from app.models.chat_session import ChatSession

class DeletarChatSessionService:
    @staticmethod
    def executar(id):
        model = ChatSession.buscar_por_id(id)
        if not model:
            raise ValueError(f"ChatSession com id {id} nao encontrado")
        model.deletar()
        return None
