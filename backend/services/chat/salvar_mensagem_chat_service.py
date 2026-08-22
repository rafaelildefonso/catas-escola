from datetime import datetime, timezone

from extensions import db
from models.message import Message
from models.chat_session import ChatSession


class SalvarMensagemChatService:
    """Salva uma mensagem em uma sessão e atualiza o updated_at da sessão."""

    ROLES_VALIDOS = ("user", "assistant", "system")

    @staticmethod
    def executar(session_id: str, role: str, content: str, metadata: dict = None) -> dict:
        if role not in SalvarMensagemChatService.ROLES_VALIDOS:
            raise ValueError(f"Role inválido: {role}. Deve ser 'user', 'assistant' ou 'system'")
        if not content:
            raise ValueError("Conteudo da mensagem e obrigatorio")

        mensagem = Message(
            session_id=session_id,
            role=role,
            content=content,
            metadata_=metadata or {},
        )
        mensagem.salvar()

        sessao = ChatSession.buscar_por_id(session_id)
        if sessao:
            sessao.updated_at = datetime.now(timezone.utc)
            db.session.commit()

        return mensagem.to_dict()
