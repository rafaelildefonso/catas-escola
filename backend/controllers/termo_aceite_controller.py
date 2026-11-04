from flask import g, jsonify, request

from core.security import login_required
from services.termo.registrar_aceite_service import RegistrarAceiteTermosService
from services.termo.consultar_aceite_service import ConsultarAceiteTermosService


class TermoAceiteController:
    """Termos de Uso e Termo de Consentimento (LGPD) — registro e consulta
    do aceite do usuário autenticado."""

    @staticmethod
    @login_required
    def consultar():
        try:
            status = ConsultarAceiteTermosService.executar(g.current_user["id"])
            return jsonify(status), 200
        except ValueError as e:
            return jsonify({"detail": str(e)}), 400

    @staticmethod
    @login_required
    def registrar():
        dados = request.get_json(silent=True) or {}
        try:
            resultado = RegistrarAceiteTermosService.executar(
                g.current_user["id"], dados
            )
            return jsonify(resultado), 201
        except ValueError as e:
            return jsonify({"detail": str(e)}), 400
