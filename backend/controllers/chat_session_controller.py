from flask import request, jsonify
from services.chat_session.criar_chat_session_service import CriarChatSessionService
from services.chat_session.listar_chat_sessions_service import ListarChatSessionsService
from services.chat_session.buscar_chat_session_service import BuscarChatSessionService
from services.chat_session.atualizar_chat_session_service import AtualizarChatSessionService
from services.chat_session.deletar_chat_session_service import DeletarChatSessionService


class ChatSessionController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarChatSessionService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarChatSessionsService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarChatSessionService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarChatSessionService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarChatSessionService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
