from flask import request, jsonify
from app.services.message.criar_message_service import CriarMessageService
from app.services.message.listar_messages_service import ListarMessagesService
from app.services.message.buscar_message_service import BuscarMessageService
from app.services.message.atualizar_message_service import AtualizarMessageService
from app.services.message.deletar_message_service import DeletarMessageService


class MessageController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarMessageService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarMessagesService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarMessageService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarMessageService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarMessageService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
