from repositories.sessoes_chat_repository import buscar_sessao_do_usuario, deletar_sessao


class ExcluirSessaoChatService:
    """Exclui uma sessao de chat pertencente ao usuario."""

    @staticmethod
    def executar(session_id: str, user_id: str) -> bool:
        sessao = buscar_sessao_do_usuario(session_id, user_id)
        if not sessao:
            raise ValueError(f"Sessao {session_id} nao encontrada ou nao pertence ao usuario")
        deletar_sessao(session_id, user_id)
        return True
