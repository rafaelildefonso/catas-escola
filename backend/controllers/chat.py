from flask import Blueprint, request, jsonify, g
from core.security import get_current_user
from core.errors import sanitize_error
from repositories import chat as chat_repo

chat_bp = Blueprint("chat", __name__, url_prefix="/api/v1/chat")


@chat_bp.route("/sessions", methods=["POST"])
def create_session():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    try:
        user_id = current_user["id"]
        data = request.get_json(silent=True) or {}
        session = chat_repo.create_session(user_id, data.get("title"))

        return jsonify({
            "status": "success",
            "message": "Sessão criada com sucesso",
            "data": session
        })
    except Exception as e:
        return jsonify({"detail": f"Erro ao criar sessão: {sanitize_error(e)}"}), 500


@chat_bp.route("/sessions", methods=["GET"])
def get_sessions():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    try:
        user_id = current_user["id"]
        limit = request.args.get("limit", 50, type=int)
        offset = request.args.get("offset", 0, type=int)
        sessions = chat_repo.get_user_sessions(user_id, limit=limit, offset=offset)

        return jsonify({
            "status": "success",
            "message": f"{len(sessions)} sessões encontradas",
            "data": sessions
        })
    except Exception as e:
        return jsonify({"detail": f"Erro ao buscar sessões: {sanitize_error(e)}"}), 500


@chat_bp.route("/sessions/<session_id>", methods=["GET"])
def get_session(session_id):
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    try:
        user_id = current_user["id"]
        session = chat_repo.get_session(session_id, user_id)

        if not session:
            return jsonify({"detail": "Sessão não encontrada"}), 404

        return jsonify({
            "status": "success",
            "message": "Sessão encontrada",
            "data": session
        })
    except Exception as e:
        return jsonify({"detail": f"Erro ao buscar sessão: {sanitize_error(e)}"}), 500


@chat_bp.route("/history/<session_id>", methods=["GET"])
def get_history(session_id):
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    try:
        user_id = current_user["id"]
        limit = request.args.get("limit", 100, type=int)
        offset = request.args.get("offset", 0, type=int)
        messages = chat_repo.get_session_messages(session_id, user_id, limit=limit, offset=offset)

        return jsonify({
            "status": "success",
            "message": f"{len(messages)} mensagens encontradas",
            "data": messages
        })
    except ValueError as e:
        return jsonify({"detail": str(e)}), 404
    except Exception as e:
        return jsonify({"detail": f"Erro ao buscar histórico: {sanitize_error(e)}"}), 500


@chat_bp.route("/sessions/<session_id>/title", methods=["PATCH"])
def update_session_title(session_id):
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    try:
        user_id = current_user["id"]
        data = request.get_json(silent=True) or {}
        title = data.get("title")

        if not title:
            return jsonify({"detail": "Título é obrigatório"}), 400

        session = chat_repo.update_session_title(session_id, user_id, title)

        return jsonify({
            "status": "success",
            "message": "Título atualizado com sucesso",
            "data": session
        })
    except ValueError as e:
        return jsonify({"detail": str(e)}), 404
    except Exception as e:
        return jsonify({"detail": f"Erro ao atualizar título: {sanitize_error(e)}"}), 500


@chat_bp.route("/sessions/<session_id>", methods=["DELETE"])
def delete_session(session_id):
    current_user = get_current_user()
    if not current_user:
        return jsonify({"detail": "Não autorizado"}), 401

    try:
        user_id = current_user["id"]
        chat_repo.delete_session(session_id, user_id)

        return jsonify({
            "status": "success",
            "message": "Sessão deletada com sucesso"
        })
    except ValueError as e:
        return jsonify({"detail": str(e)}), 404
    except Exception as e:
        return jsonify({"detail": f"Erro ao deletar sessão: {sanitize_error(e)}"}), 500
