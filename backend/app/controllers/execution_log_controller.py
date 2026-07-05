from flask import request, jsonify
from app.services.execution_log.criar_execution_log_service import CriarExecutionLogService
from app.services.execution_log.listar_execution_logs_service import ListarExecutionLogsService
from app.services.execution_log.buscar_execution_log_service import BuscarExecutionLogService
from app.services.execution_log.atualizar_execution_log_service import AtualizarExecutionLogService
from app.services.execution_log.deletar_execution_log_service import DeletarExecutionLogService


class ExecutionLogController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarExecutionLogService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarExecutionLogsService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarExecutionLogService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarExecutionLogService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarExecutionLogService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
