from flask import jsonify, request

from app.services.relatorio.buscar_mensagens_service import BuscarMensagensService
from app.services.relatorio.gerar_estatisticas_dashboard_service import GerarEstatisticasDashboardService
from app.services.relatorio.gerar_relatorio_automacoes_service import GerarRelatorioAutomacoesService
from app.services.relatorio.gerar_relatorio_chat_service import GerarRelatorioChatService


class RelatorioController:
    """Controller dos relatórios e buscas além do CRUD básico."""

    @staticmethod
    def estatisticas_dashboard():
        args = request.args
        try:
            resultado = GerarEstatisticasDashboardService.executar(
                user_id=args.get("user_id"),
                dias=args.get("dias", 7),
            )
            return jsonify(resultado), 200
        except ValueError as e:
            return jsonify({"detail": str(e)}), 400

    @staticmethod
    def relatorio_automacoes():
        args = request.args
        try:
            resultado = GerarRelatorioAutomacoesService.executar(
                user_id=args.get("user_id"),
                status=args.get("status"),
                data_inicio=args.get("data_inicio"),
                data_fim=args.get("data_fim"),
                busca=args.get("busca"),
                ordem=args.get("ordem", "created_at"),
                limite=args.get("limite", 50),
                deslocamento=args.get("deslocamento", 0),
            )
            return jsonify(resultado), 200
        except ValueError as e:
            return jsonify({"detail": str(e)}), 400

    @staticmethod
    def relatorio_chat():
        args = request.args
        try:
            resultado = GerarRelatorioChatService.executar(
                user_id=args.get("user_id"),
                dias=args.get("dias", 30),
            )
            return jsonify(resultado), 200
        except ValueError as e:
            return jsonify({"detail": str(e)}), 400

    @staticmethod
    def buscar_mensagens():
        args = request.args
        try:
            resultado = BuscarMensagensService.executar(
                user_id=args.get("user_id"),
                termo=args.get("termo"),
                limite=args.get("limite", 50),
                deslocamento=args.get("deslocamento", 0),
            )
            return jsonify(resultado), 200
        except ValueError as e:
            return jsonify({"detail": str(e)}), 400