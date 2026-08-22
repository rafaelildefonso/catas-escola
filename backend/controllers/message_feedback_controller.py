from flask import request, jsonify
from services.message_feedback.criar_message_feedback_service import CriarMessageFeedbackService
from services.message_feedback.listar_message_feedbacks_service import ListarMessageFeedbacksService
from services.message_feedback.buscar_message_feedback_service import BuscarMessageFeedbackService
from services.message_feedback.atualizar_message_feedback_service import AtualizarMessageFeedbackService
from services.message_feedback.deletar_message_feedback_service import DeletarMessageFeedbackService


class MessageFeedbackController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarMessageFeedbackService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarMessageFeedbacksService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarMessageFeedbackService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarMessageFeedbackService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarMessageFeedbackService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
