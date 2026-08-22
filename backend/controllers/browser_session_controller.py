from flask import request, jsonify
from services.browser_session.criar_browser_session_service import CriarBrowserSessionService
from services.browser_session.listar_browser_sessions_service import ListarBrowserSessionsService
from services.browser_session.buscar_browser_session_service import BuscarBrowserSessionService
from services.browser_session.atualizar_browser_session_service import AtualizarBrowserSessionService
from services.browser_session.deletar_browser_session_service import DeletarBrowserSessionService


class BrowserSessionController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarBrowserSessionService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarBrowserSessionsService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarBrowserSessionService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarBrowserSessionService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarBrowserSessionService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
