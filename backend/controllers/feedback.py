from flask import Blueprint, request, jsonify
from core.security import get_current_user
from core.errors import sanitize_error
from repositories import feedback as feedback_repo
from repositories import chat as chat_repo

feedback_bp = Blueprint("feedback", __name__, url_prefix="/api/v1/chat")


@feedback_bp.route("/messages/<message_id>/feedback", methods=["POST"])
def upsert_message_feedback(message_id):
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]
    data = request.get_json(silent=True) or {}
    is_liked = data.get("is_liked")
    session_id = data.get("session_id")
    reason = data.get("reason")

    try:
        if is_liked is None:
            feedback_repo.delete_feedback(message_id, user_id)
            return jsonify({"status": "success", "message": "Feedback removido"})

        record = feedback_repo.upsert_feedback(
            message_id=message_id,
            user_id=user_id,
            session_id=session_id,
            is_liked=is_liked,
            reason=reason,
        )

        return jsonify({
            "status": "success",
            "message": "Feedback salvo com sucesso",
            "data": record,
        })
    except RuntimeError as e:
        return jsonify({"detail": sanitize_error(e)}), 500
    except Exception as e:
        return jsonify({"detail": sanitize_error(e)}), 500


@feedback_bp.route("/sessions/<session_id>/feedback", methods=["GET"])
def get_session_feedback_summary(session_id):
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    user_id = current_user["id"]

    session = chat_repo.get_session(session_id, user_id)
    if not session:
        return jsonify({"detail": "Sessão não encontrada"}), 404

    try:
        summary = feedback_repo.get_feedback_summary(session_id)
        return jsonify({"status": "success", "data": summary})
    except RuntimeError as e:
        return jsonify({"detail": sanitize_error(e)}), 500
