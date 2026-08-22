from app.repositories.sessoes_chat_repository import buscar_sessao_do_usuario


class RenomearSessaoChatService:
    """Renomeia o título de uma sessão do usuário."""

    @staticmethod
    def executar(session_id: str, user_id: str, titulo: str) -> dict:
        if not titulo:
            raise ValueError("Título é obrigatório")

        sessao = buscar_sessao_do_usuario(session_id, user_id)
        if not sessao:
            raise ValueError(f"Sessão {session_id} não encontrada ou não pertence ao usuário")

        sessao.title = titulo
        from app.extensions import db
        db.session.commit()
        return sessao.to_dict()
