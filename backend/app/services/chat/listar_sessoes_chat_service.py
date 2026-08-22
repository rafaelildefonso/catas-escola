from app.repositories.sessoes_chat_repository import listar_sessoes_do_usuario


class ListarSessoesChatService:
    """Lista as sessões de chat do usuário com paginação."""

    @staticmethod
    def executar(user_id: str, limite: int = 50, deslocamento: int = 0) -> list:
        if not user_id:
            raise ValueError("user_id e obrigatorio")
        return listar_sessoes_do_usuario(user_id, limite=limite, deslocamento=deslocamento)
