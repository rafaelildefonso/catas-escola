from flask import g, jsonify, request

from core.config import settings
from core.security import login_required
from services.storage.attachment_service import AttachmentError, AttachmentService


class AttachmentController:
    @staticmethod
    @login_required
    def upload():
        if request.content_length and request.content_length > settings.ATTACHMENTS_MAX_SIZE_BYTES + 1024 * 1024:
            return jsonify({"detail": "O arquivo excede o limite de 10 MB."}), 413
        arquivo = request.files.get("file")
        if not arquivo:
            return jsonify({"detail": "Envie um arquivo no campo 'file'."}), 400
        try:
            conteudo = arquivo.read(settings.ATTACHMENTS_MAX_SIZE_BYTES + 1)
            resultado = AttachmentService.upload(
                user_id=g.current_user["id"],
                nome=arquivo.filename or "",
                content_type=arquivo.mimetype or "",
                conteudo=conteudo,
            )
            return jsonify(resultado), 201
        except AttachmentError as erro:
            return jsonify({"detail": str(erro)}), erro.status_code

    @staticmethod
    @login_required
    def listar():
        try:
            return jsonify(AttachmentService.listar(g.current_user["id"])), 200
        except AttachmentError as erro:
            return jsonify({"detail": str(erro)}), erro.status_code

    @staticmethod
    @login_required
    def excluir(attachment_id):
        try:
            AttachmentService.excluir(g.current_user["id"], attachment_id)
            return "", 204
        except AttachmentError as erro:
            return jsonify({"detail": str(erro)}), erro.status_code

    @staticmethod
    @login_required
    def visualizar_docx(attachment_id):
        try:
            return jsonify(
                AttachmentService.visualizar_docx(g.current_user["id"], attachment_id)
            ), 200
        except AttachmentError as erro:
            return jsonify({"detail": str(erro)}), erro.status_code
