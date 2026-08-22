from flask import request, jsonify
from services.integration.criar_integration_service import CriarIntegrationService
from services.integration.listar_integrations_service import ListarIntegrationsService
from services.integration.buscar_integration_service import BuscarIntegrationService
from services.integration.atualizar_integration_service import AtualizarIntegrationService
from services.integration.deletar_integration_service import DeletarIntegrationService


class IntegrationController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarIntegrationService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarIntegrationsService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarIntegrationService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarIntegrationService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarIntegrationService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
