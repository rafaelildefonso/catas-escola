from io import BytesIO
from flask import g, jsonify, send_file

from core.security import login_required
from services.relatorio.relatorios_gerados_service import RelatoriosGeradosService


class RelatoriosGeradosController:
    @staticmethod
    @login_required
    def listar():
        return jsonify(RelatoriosGeradosService.listar(g.current_user["id"])), 200

    @staticmethod
    @login_required
    def baixar(report_id):
        try:
            report = RelatoriosGeradosService.buscar_pdf(g.current_user["id"], report_id)
            return send_file(
                BytesIO(report.pdf_content),
                mimetype="application/pdf",
                as_attachment=True,
                download_name=f"{report.title.strip() or 'relatorio'}.pdf",
            )
        except ValueError as error:
            return jsonify({"detail": str(error)}), 404
