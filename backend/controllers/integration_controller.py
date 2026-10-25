from flask import request, jsonify
from core.security import get_current_user, login_required
from services.integration.criar_integration_service import CriarIntegrationService
from services.integration.listar_integrations_service import ListarIntegrationsService
from services.integration.buscar_integration_service import BuscarIntegrationService
from services.integration.atualizar_integration_service import AtualizarIntegrationService
from services.integration.deletar_integration_service import DeletarIntegrationService


class IntegrationController:

    @staticmethod
    def _public_data(model):
        data = model.to_dict()
        data.pop("access_token", None)
        data.pop("refresh_token", None)
        return data

    @staticmethod
    @login_required
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarIntegrationService.executar(dados, get_current_user()["id"])
            return jsonify(IntegrationController._public_data(model)), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    @login_required
    def listar():
        models = ListarIntegrationsService.executar(user_id=get_current_user()["id"])
        return jsonify([IntegrationController._public_data(m) for m in models]), 200

    @staticmethod
    @login_required
    def buscar_por_id(id):
        try:
            model = BuscarIntegrationService.executar(id, get_current_user()["id"])
            return jsonify(IntegrationController._public_data(model)), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    @login_required
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarIntegrationService.executar(id, dados, get_current_user()["id"])
            return jsonify(IntegrationController._public_data(model)), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400 if "Dados" in str(e) else 404

    @staticmethod
    @login_required
    def deletar(id):
        try:
            DeletarIntegrationService.executar(id, get_current_user()["id"])
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    @login_required
    def deletar_por_provider(provider):
        try:
            DeletarIntegrationService.executar_por_provider(get_current_user()["id"], provider)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
