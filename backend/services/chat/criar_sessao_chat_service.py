from models.chat_session import ChatSession


class CriarSessaoChatService:
    """Cria uma nova sessão de chat para o usuário."""

    @staticmethod
    def executar(user_id: str, titulo: str = None, is_onboarding: bool = False) -> dict:
        if not user_id:
            raise ValueError("user_id e obrigatorio")

        sessao = ChatSession(
            user_id=user_id,
            title=titulo or "Nova Conversa",
            is_onboarding=bool(is_onboarding),
        )
        sessao.salvar()
        return sessao.to_dict()
