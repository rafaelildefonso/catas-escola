from flask import request, jsonify
from app.services.ia_memory.criar_ia_memory_service import CriarIaMemoryService
from app.services.ia_memory.listar_ia_memorys_service import ListarIaMemorysService
from app.services.ia_memory.buscar_ia_memory_service import BuscarIaMemoryService
from app.services.ia_memory.atualizar_ia_memory_service import AtualizarIaMemoryService
from app.services.ia_memory.deletar_ia_memory_service import DeletarIaMemoryService


class IaMemoryController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarIaMemoryService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarIaMemorysService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarIaMemoryService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarIaMemoryService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarIaMemoryService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
