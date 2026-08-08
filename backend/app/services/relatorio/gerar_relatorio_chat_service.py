from app.repositories.chat_repository import relatorio_chat


class GerarRelatorioChatService:
    """Caso de uso: resumo de conversas, mensagens e feedback do chat."""

    @staticmethod
    def executar(user_id: str, dias=None) -> dict:
        if not user_id:
            raise ValueError("user_id e obrigatorio")

        try:
            dias_int = max(1, min(int(dias), 365))
        except (TypeError, ValueError):
            dias_int = 30

        return relatorio_chat(user_id, dias_int)