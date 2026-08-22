from flask import request, jsonify
from services.page_analysis_cache.criar_page_analysis_cache_service import CriarPageAnalysisCacheService
from services.page_analysis_cache.listar_page_analysis_caches_service import ListarPageAnalysisCachesService
from services.page_analysis_cache.buscar_page_analysis_cache_service import BuscarPageAnalysisCacheService
from services.page_analysis_cache.atualizar_page_analysis_cache_service import AtualizarPageAnalysisCacheService
from services.page_analysis_cache.deletar_page_analysis_cache_service import DeletarPageAnalysisCacheService


class PageAnalysisCacheController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarPageAnalysisCacheService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarPageAnalysisCachesService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarPageAnalysisCacheService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarPageAnalysisCacheService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarPageAnalysisCacheService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
