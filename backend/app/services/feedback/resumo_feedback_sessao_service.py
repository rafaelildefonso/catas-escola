from app.repositories.feedbacks_repository import resumo_da_sessao as _resumo


class ResumoFeedbackSessaoService:
    """Caso de uso: consultar o resumo de feedback (likes/dislikes) de uma sessão."""

    @staticmethod
    def executar(session_id: str) -> dict:
        if not session_id:
            raise ValueError("session_id e obrigatorio")
        return _resumo(session_id)
