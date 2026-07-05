from flask import request, jsonify
from app.services.automation_generation_log.criar_automation_generation_log_service import CriarAutomationGenerationLogService
from app.services.automation_generation_log.listar_automation_generation_logs_service import ListarAutomationGenerationLogsService
from app.services.automation_generation_log.buscar_automation_generation_log_service import BuscarAutomationGenerationLogService
from app.services.automation_generation_log.atualizar_automation_generation_log_service import AtualizarAutomationGenerationLogService
from app.services.automation_generation_log.deletar_automation_generation_log_service import DeletarAutomationGenerationLogService


class AutomationGenerationLogController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarAutomationGenerationLogService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarAutomationGenerationLogsService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarAutomationGenerationLogService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarAutomationGenerationLogService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarAutomationGenerationLogService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
