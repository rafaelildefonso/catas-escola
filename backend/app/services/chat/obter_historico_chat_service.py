from app.services.chat.obter_sessao_chat_service import ObterSessaoChatService
from app.repositories.sessoes_chat_repository import listar_mensagens_da_sessao


class ObterHistoricoChatService:
    """Obtém o histórico de mensagens de uma sessão do usuário, com paginação."""

    @staticmethod
    def executar(session_id: str, user_id: str, limite: int = 100, deslocamento: int = 0) -> list:
        ObterSessaoChatService.executar(session_id, user_id)
        return listar_mensagens_da_sessao(session_id, limite=limite, deslocamento=deslocamento)
