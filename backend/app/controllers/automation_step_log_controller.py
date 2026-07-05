from flask import request, jsonify
from app.services.automation_step_log.criar_automation_step_log_service import CriarAutomationStepLogService
from app.services.automation_step_log.listar_automation_step_logs_service import ListarAutomationStepLogsService
from app.services.automation_step_log.buscar_automation_step_log_service import BuscarAutomationStepLogService
from app.services.automation_step_log.atualizar_automation_step_log_service import AtualizarAutomationStepLogService
from app.services.automation_step_log.deletar_automation_step_log_service import DeletarAutomationStepLogService


class AutomationStepLogController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarAutomationStepLogService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarAutomationStepLogsService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarAutomationStepLogService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarAutomationStepLogService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarAutomationStepLogService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
