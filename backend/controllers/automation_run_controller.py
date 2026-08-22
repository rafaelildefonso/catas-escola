from flask import request, jsonify
from services.automation_run.criar_automation_run_service import CriarAutomationRunService
from services.automation_run.listar_automation_runs_service import ListarAutomationRunsService
from services.automation_run.buscar_automation_run_service import BuscarAutomationRunService
from services.automation_run.atualizar_automation_run_service import AtualizarAutomationRunService
from services.automation_run.deletar_automation_run_service import DeletarAutomationRunService


class AutomationRunController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarAutomationRunService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarAutomationRunsService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarAutomationRunService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarAutomationRunService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarAutomationRunService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
