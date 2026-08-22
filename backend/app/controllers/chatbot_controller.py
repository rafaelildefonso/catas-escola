from flask import jsonify, request

from core.security import get_current_user
from core.errors import sanitize_error

from app.services.chat.enviar_mensagem_chat_service import EnviarMensagemChatService
from app.services.chat.continuar_mensagem_chat_service import ContinuarMensagemChatService
from app.services.chat.excecoes_chat import ErroPermissao, ErroNaoEncontrado


class ChatbotController:
    """Controller do fluxo de IA do chatbot (/api/v1/chat/message)."""

    @staticmethod
    def enviar_mensagem():
        current_user = get_current_user()
        if not current_user:
            return jsonify({"detail": "Não autorizado"}), 401

        try:
            dados = request.get_json(silent=True) or {}
            resposta = EnviarMensagemChatService.executar(current_user["id"], dados)
            return jsonify(resposta)
        except ValueError as e:
            return jsonify({"detail": str(e)}), 400
        except ErroPermissao as e:
            return jsonify({"detail": str(e)}), 403
        except Exception as e:
            return jsonify({"detail": f"Erro ao processar mensagem: {sanitize_error(e)}"}), 500

    @staticmethod
    def continuar_mensagem():
        current_user = get_current_user()
        if not current_user:
            return jsonify({"detail": "Não autorizado"}), 401

        try:
            dados = request.get_json(silent=True) or {}
            resposta = ContinuarMensagemChatService.executar(current_user["id"], dados)
            return jsonify(resposta)
        except ValueError as e:
            return jsonify({"detail": str(e)}), 400
        except ErroNaoEncontrado as e:
            return jsonify({"detail": str(e)}), 404
        except Exception as e:
            return jsonify({"detail": f"Erro ao processar mensagem: {sanitize_error(e)}"}), 500
