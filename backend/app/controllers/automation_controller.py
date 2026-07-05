from flask import request, jsonify
from app.services.automation.criar_automation_service import CriarAutomationService
from app.services.automation.listar_automations_service import ListarAutomationsService
from app.services.automation.buscar_automation_service import BuscarAutomationService
from app.services.automation.atualizar_automation_service import AtualizarAutomationService
from app.services.automation.deletar_automation_service import DeletarAutomationService


class AutomationController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarAutomationService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarAutomationsService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarAutomationService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarAutomationService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarAutomationService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
