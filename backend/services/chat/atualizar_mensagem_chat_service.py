from extensions import db
from models.message import Message


class AtualizarMensagemChatService:
    """Atualiza conteúdo e/ou metadados de uma mensagem (mesclando metadados existentes)."""

    @staticmethod
    def executar(message_id: str, content: str = None, metadata: dict = None) -> dict:
        mensagem = Message.buscar_por_id(message_id)
        if not mensagem:
            raise ValueError(f"Mensagem {message_id} não encontrada")

        if content is not None:
            mensagem.content = content

        if metadata is not None:
            atual = dict(mensagem.metadata_ or {})
            atual.update(metadata)
            mensagem.metadata_ = atual

        db.session.commit()
        return mensagem.to_dict()
