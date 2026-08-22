from extensions import db
from models.message_feedback import MessageFeedback
from repositories.feedbacks_repository import buscar_por_mensagem_e_usuario


class RegistrarFeedbackService:
    """Caso de uso: registrar/atualizar/remover o feedback do usuário sobre uma mensagem.

    is_liked=None remove o feedback; caso contrário faz upsert.
    """

    @staticmethod
    def executar(user_id: str, message_id: str, is_liked, session_id=None, reason=None):
        if not message_id:
            raise ValueError("message_id e obrigatorio")

        if is_liked is None:
            registro = buscar_por_mensagem_e_usuario(message_id, user_id)
            if registro:
                registro.deletar()
            return None

        registro = buscar_por_mensagem_e_usuario(message_id, user_id)
        if registro:
            registro.is_liked = bool(is_liked)
            if reason is not None:
                registro.reason = reason
            if session_id:
                registro.session_id = session_id
            db.session.commit()
        else:
            if not session_id:
                raise ValueError("session_id e obrigatorio para novo feedback")
            registro = MessageFeedback(
                message_id=message_id,
                user_id=user_id,
                session_id=session_id,
                is_liked=bool(is_liked),
                reason=reason,
            )
            registro.salvar()

        return registro.to_dict()
