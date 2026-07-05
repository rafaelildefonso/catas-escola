from flask import request, jsonify
from app.services.ai_suggestion.criar_ai_suggestion_service import CriarAiSuggestionService
from app.services.ai_suggestion.listar_ai_suggestions_service import ListarAiSuggestionsService
from app.services.ai_suggestion.buscar_ai_suggestion_service import BuscarAiSuggestionService
from app.services.ai_suggestion.atualizar_ai_suggestion_service import AtualizarAiSuggestionService
from app.services.ai_suggestion.deletar_ai_suggestion_service import DeletarAiSuggestionService


class AiSuggestionController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarAiSuggestionService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarAiSuggestionsService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarAiSuggestionService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarAiSuggestionService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarAiSuggestionService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
