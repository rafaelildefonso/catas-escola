from app.models.chat_session import ChatSession

class AtualizarChatSessionService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = ChatSession.buscar_por_id(id)
        if not model:
            raise ValueError(f"ChatSession com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
