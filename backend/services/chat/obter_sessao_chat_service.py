from repositories.sessoes_chat_repository import buscar_sessao_do_usuario


def _normalizar_sessao(sessao: dict) -> dict:
    if "is_onboarding" in sessao:
        v = sessao["is_onboarding"]
        if isinstance(v, int):
            sessao["is_onboarding"] = bool(v)
    return sessao


class ObterSessaoChatService:
    """Obtem uma sessao de chat garantindo que pertence ao usuario."""

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
            raise ValueError(f"Sessao {session_id} nao encontrada ou nao pertence ao usuario")
        return _normalizar_sessao(sessao)
