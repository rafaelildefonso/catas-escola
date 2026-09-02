from models.message_feedback import MessageFeedback
from repositories.feedbacks_repository import (
    buscar_por_mensagem_e_usuario,
    atualizar_por_mensagem_e_usuario,
    deletar_por_mensagem_e_usuario,
)


class RegistrarFeedbackService:
    """Caso de uso: registrar/atualizar/remover o feedback do usuario sobre uma mensagem.

    is_liked=None remove o feedback; caso contrario faz upsert.
    """

    @staticmethod
    def executar(user_id: str, message_id: str, is_liked, session_id=None, reason=None):
        if not message_id:
            raise ValueError("message_id e obrigatorio")

        if is_liked is None:
            deletar_por_mensagem_e_usuario(message_id, user_id)
            return None

        registro = buscar_por_mensagem_e_usuario(message_id, user_id)
        if registro:
            atualizado = atualizar_por_mensagem_e_usuario(
                message_id,
                user_id,
                is_liked=bool(is_liked),
                **({"reason": reason} if reason is not None else {}),
                **({"session_id": session_id} if session_id else {}),
            )
            return atualizado
        else:
            if not session_id:
                raise ValueError("session_id e obrigatorio para novo feedback")
            novo = MessageFeedback(
                message_id=message_id,
                user_id=user_id,
                session_id=session_id,
                is_liked=bool(is_liked),
                reason=reason,
            )
            novo.salvar()
            return novo.to_dict()
