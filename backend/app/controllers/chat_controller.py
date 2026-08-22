from flask import jsonify, request

from core.security import get_current_user
from core.errors import sanitize_error

from app.services.chat.criar_sessao_chat_service import CriarSessaoChatService
from app.services.chat.listar_sessoes_chat_service import ListarSessoesChatService
from app.services.chat.obter_sessao_chat_service import ObterSessaoChatService
from app.services.chat.obter_historico_chat_service import ObterHistoricoChatService
from app.services.chat.renomear_sessao_chat_service import RenomearSessaoChatService
from app.services.chat.excluir_sessao_chat_service import ExcluirSessaoChatService


class ChatController:
    """Controller das sessões de chat do usuário (/api/v1/chat)."""

    @staticmethod
    def _usuario_autenticado():
        return get_current_user()

    @staticmethod
    def criar_sessao():
        current_user = ChatController._usuario_autenticado()
        if not current_user:
            return jsonify({"detail": "Não autorizado"}), 401

        try:
            dados = request.get_json(silent=True) or {}
            sessao = CriarSessaoChatService.executar(
                user_id=current_user["id"],
                titulo=dados.get("title"),
            )
            return jsonify({
                "status": "success",
                "message": "Sessão criada com sucesso",
                "data": sessao,
            })
        except Exception as e:
            return jsonify({"detail": f"Erro ao criar sessão: {sanitize_error(e)}"}), 500

    @staticmethod
    def listar_sessoes():
        current_user = ChatController._usuario_autenticado()
        if not current_user:
            return jsonify({"detail": "Não autorizado"}), 401

        try:
            limite = request.args.get("limit", 50, type=int)
            deslocamento = request.args.get("offset", 0, type=int)
            sessoes = ListarSessoesChatService.executar(
                user_id=current_user["id"], limite=limite, deslocamento=deslocamento
            )
            return jsonify({
                "status": "success",
                "message": f"{len(sessoes)} sessões encontradas",
                "data": sessoes,
            })
        except Exception as e:
            return jsonify({"detail": f"Erro ao buscar sessões: {sanitize_error(e)}"}), 500

    @staticmethod
    def obter_sessao(session_id):
        current_user = ChatController._usuario_autenticado()
        if not current_user:
            return jsonify({"detail": "Não autorizado"}), 401

        try:
            sessao = ObterSessaoChatService.executar(session_id, current_user["id"])
            return jsonify({
                "status": "success",
                "message": "Sessão encontrada",
                "data": sessao,
            })
        except ValueError as e:
            return jsonify({"detail": str(e)}), 404
        except Exception as e:
            return jsonify({"detail": f"Erro ao buscar sessão: {sanitize_error(e)}"}), 500

    @staticmethod
    def obter_historico(session_id):
        current_user = ChatController._usuario_autenticado()
        if not current_user:
            return jsonify({"detail": "Não autorizado"}), 401

        try:
            limite = request.args.get("limit", 100, type=int)
            deslocamento = request.args.get("offset", 0, type=int)
            mensagens = ObterHistoricoChatService.executar(
                session_id, current_user["id"], limite=limite, deslocamento=deslocamento
            )
            return jsonify({
                "status": "success",
                "message": f"{len(mensagens)} mensagens encontradas",
                "data": mensagens,
            })
        except ValueError as e:
            return jsonify({"detail": str(e)}), 404
        except Exception as e:
            return jsonify({"detail": f"Erro ao buscar histórico: {sanitize_error(e)}"}), 500

    @staticmethod
    def renomear_sessao(session_id):
        current_user = ChatController._usuario_autenticado()
        if not current_user:
            return jsonify({"detail": "Não autorizado"}), 401

        dados = request.get_json(silent=True) or {}
        titulo = dados.get("title")
        if not titulo:
            return jsonify({"detail": "Título é obrigatório"}), 400

        try:
            sessao = RenomearSessaoChatService.executar(session_id, current_user["id"], titulo)
            return jsonify({
                "status": "success",
                "message": "Título atualizado com sucesso",
                "data": sessao,
            })
        except ValueError as e:
            return jsonify({"detail": str(e)}), 404
        except Exception as e:
            return jsonify({"detail": f"Erro ao atualizar título: {sanitize_error(e)}"}), 500

    @staticmethod
    def excluir_sessao(session_id):
        current_user = ChatController._usuario_autenticado()
        if not current_user:
            return jsonify({"detail": "Não autorizado"}), 401

        try:
            ExcluirSessaoChatService.executar(session_id, current_user["id"])
            return jsonify({
                "status": "success",
                "message": "Sessão deletada com sucesso",
            })
        except ValueError as e:
            return jsonify({"detail": str(e)}), 404
        except Exception as e:
            return jsonify({"detail": f"Erro ao deletar sessão: {sanitize_error(e)}"}), 500
