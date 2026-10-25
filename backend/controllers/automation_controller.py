from flask import g, jsonify, request

from core.security import login_required
from services.automation.atualizar_automation_service import AtualizarAutomationService
from services.automation.buscar_automation_service import BuscarAutomationService
from services.automation.criar_automation_service import CriarAutomationService
from services.automation.deletar_automation_service import DeletarAutomationService
from services.automation.listar_automations_service import ListarAutomationsService


class AutomationController:

    @staticmethod
    @login_required
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarAutomationService.executar(dados, g.current_user["id"])
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    @login_required
    def listar():
        try:
            models = ListarAutomationsService.executar(g.current_user["id"], request.args.get("status"))
            return jsonify([m.to_dict() for m in models]), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    @login_required
    def buscar_por_id(id):
        try:
            model = BuscarAutomationService.executar(id, g.current_user["id"])
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    @login_required
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarAutomationService.executar(id, dados, g.current_user["id"])
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404 if "nao encontrado" in str(e) else 400

    @staticmethod
    @login_required
    def deletar(id):
        try:
            DeletarAutomationService.executar(id, g.current_user["id"])
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    @login_required
    def schedule(id):
        from services.automation.atualizar_automation_service import (
            AtualizarAutomationService,
        )

        data = request.get_json(silent=True) or {}
        if not isinstance(data, dict):
            return jsonify({"detail": "Envie um objeto JSON"}), 400
        trigger = data.get("trigger")
        if not isinstance(trigger, dict) or trigger.get("type") not in {"cron", "schedule"}:
            return jsonify({"detail": "Informe trigger cron ou schedule."}), 400
        try:
            model = AtualizarAutomationService.executar(id, {"trigger": trigger}, g.current_user["id"])
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404 if "nao encontrado" in str(e) else 400

    @staticmethod
    @login_required
    def executar(id):
        from services.automation.dispatch import dispatch_automation

        try:
            run = dispatch_automation(id, g.current_user["id"], "manual")
            return jsonify(run.to_dict()), 503 if run.status == "failed" else 202
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404 if "não encontrada" in str(e) else 400

    @staticmethod
    @login_required
    def revisar(id):
        from services.automation.revisar_automation_service import (
            RevisarAutomationService,
        )

        data = request.get_json(silent=True) or {}
        if not isinstance(data, dict):
            return jsonify({"detail": "Envie um objeto JSON"}), 400
        try:
            model = RevisarAutomationService.executar(id, g.current_user["id"], data.get("request"))
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({"detail": str(e)}), 404 if "nao encontrado" in str(e) else 400
