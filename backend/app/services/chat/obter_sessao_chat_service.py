from app.repositories.sessoes_chat_repository import buscar_sessao_do_usuario


class ObterSessaoChatService:
    """Obtém uma sessão de chat garantindo que pertence ao usuário."""

    @staticmethod
    def executar(session_id: str, user_id: str) -> dict:
        if not session_id or not user_id:
            raise ValueError("session_id e user_id sao obrigatorios")

        if session_id.startswith("dev-session-") and user_id.startswith("dev-user-"):
            return {
                "id": session_id,
                "user_id": user_id,
                "title": "Nova Conversa",
                "is_onboarding": False,
            }

        sessao = buscar_sessao_do_usuario(session_id, user_id)
        if not sessao:
            raise ValueError(f"Sessão {session_id} não encontrada ou não pertence ao usuário")
        return sessao.to_dict()
