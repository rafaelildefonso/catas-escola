from repositories.sessoes_chat_repository import buscar_sessao_do_usuario, atualizar_sessao


class RenomearSessaoChatService:
    """Renomeia o titulo de uma sessao do usuario."""

    @staticmethod
    def executar(session_id: str, user_id: str, titulo: str) -> dict:
        if not titulo:
            raise ValueError("Titulo e obrigatorio")

        sessao = buscar_sessao_do_usuario(session_id, user_id)
        if not sessao:
            raise ValueError(f"Sessao {session_id} nao encontrada ou nao pertence ao usuario")

        return atualizar_sessao(session_id, user_id, title=titulo)
