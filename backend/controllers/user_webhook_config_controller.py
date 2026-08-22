from flask import request, jsonify
from services.user_webhook_config.criar_user_webhook_config_service import CriarUserWebhookConfigService
from services.user_webhook_config.listar_user_webhook_configs_service import ListarUserWebhookConfigsService
from services.user_webhook_config.buscar_user_webhook_config_service import BuscarUserWebhookConfigService
from services.user_webhook_config.atualizar_user_webhook_config_service import AtualizarUserWebhookConfigService
from services.user_webhook_config.deletar_user_webhook_config_service import DeletarUserWebhookConfigService


class UserWebhookConfigController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarUserWebhookConfigService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarUserWebhookConfigsService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarUserWebhookConfigService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarUserWebhookConfigService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarUserWebhookConfigService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
