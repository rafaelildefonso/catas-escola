from flask import jsonify, request

from core.security import get_current_user
from core.errors import sanitize_error

from services.feedback.registrar_feedback_service import RegistrarFeedbackService
from services.feedback.resumo_feedback_sessao_service import ResumoFeedbackSessaoService
from services.chat.obter_sessao_chat_service import ObterSessaoChatService


class FeedbackController:
    """Controller do feedback do usuário sobre mensagens do assistente."""

    @staticmethod
    def registrar_feedback(message_id):
        current_user = get_current_user()
        if not current_user:
            return jsonify({"detail": "Não autorizado"}), 401

        user_id = current_user["id"]
        dados = request.get_json(silent=True) or {}

        try:
            registro = RegistrarFeedbackService.executar(
                user_id=user_id,
                message_id=message_id,
                is_liked=dados.get("is_liked"),
                session_id=dados.get("session_id"),
                reason=dados.get("reason"),
            )

            if registro is None:
                return jsonify({"status": "success", "message": "Feedback removido"})

            return jsonify({
                "status": "success",
                "message": "Feedback salvo com sucesso",
                "data": registro,
            })
        except ValueError as e:
            return jsonify({"detail": sanitize_error(e)}), 400
        except Exception as e:
            return jsonify({"detail": sanitize_error(e)}), 500

    @staticmethod
    def resumo_da_sessao(session_id):
        current_user = get_current_user()
        if not current_user:
            return jsonify({"detail": "Não autorizado"}), 401

        try:
            ObterSessaoChatService.executar(session_id, current_user["id"])
        except ValueError as e:
            return jsonify({"detail": str(e)}), 404

        try:
            resumo = ResumoFeedbackSessaoService.executar(session_id)
            return jsonify({"status": "success", "data": resumo})
        except Exception as e:
            return jsonify({"detail": sanitize_error(e)}), 500
