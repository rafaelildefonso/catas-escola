from flask import request, jsonify
from app.services.page_context.criar_page_context_service import CriarPageContextService
from app.services.page_context.listar_page_contexts_service import ListarPageContextsService
from app.services.page_context.buscar_page_context_service import BuscarPageContextService
from app.services.page_context.atualizar_page_context_service import AtualizarPageContextService
from app.services.page_context.deletar_page_context_service import DeletarPageContextService


class PageContextController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarPageContextService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarPageContextsService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarPageContextService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarPageContextService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarPageContextService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
