from repositories.sessoes_chat_repository import buscar_sessao_do_usuario


class ExcluirSessaoChatService:
    """Exclui uma sessão de chat pertencente ao usuário."""

    @staticmethod
    def executar(session_id: str, user_id: str) -> bool:
        sessao = buscar_sessao_do_usuario(session_id, user_id)
        if not sessao:
            raise ValueError(f"Sessão {session_id} não encontrada ou não pertence ao usuário")
        sessao.deletar()
        return True
