from flask import request, jsonify
from services.profile.criar_profile_service import CriarProfileService
from services.profile.buscar_profile_service import BuscarProfileService
from services.profile.atualizar_profile_service import (
    AtualizarProfileService,
    ProfileFieldProtectedError,
)
from services.profile.deletar_profile_service import DeletarProfileService
from core.security import get_current_user, login_required
from flask import g


class ProfileController:

    @staticmethod
    @login_required
    def criar():
        dados = request.get_json(silent=True) or {}
        if not isinstance(dados, dict):
            return jsonify({"detail": "Envie um objeto JSON"}), 400
        try:
            BuscarProfileService.executar(g.current_user["id"])
            return jsonify({"detail": "Perfil já existe"}), 409
        except ValueError:
            pass
        try:
            model = CriarProfileService.executar({**dados, "id": g.current_user["id"]})
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    @login_required
    def listar():
        try:
            model = BuscarProfileService.executar(g.current_user["id"])
            return jsonify([model.to_dict()]), 200
        except ValueError:
            return jsonify([]), 200

    @staticmethod
    @login_required
    def buscar_por_id(id):
        if id != g.current_user["id"]:
            return jsonify({"detail": "Perfil não encontrado"}), 404
        try:
            model = BuscarProfileService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    @login_required
    def atualizar(id):
        if id != g.current_user["id"]:
            return jsonify({"detail": "Perfil não encontrado"}), 404
        dados = request.get_json(silent=True)
        if not isinstance(dados, dict):
            return jsonify({"detail": "Envie um objeto JSON"}), 400
        try:
            model = AtualizarProfileService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ProfileFieldProtectedError as e:
            return jsonify({'detail': str(e)}), 400
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar_me():
        current_user = get_current_user()
        if not current_user:
            return jsonify({"detail": "Não autorizado"}), 401
        dados = request.get_json(silent=True)
        if not isinstance(dados, dict):
            return jsonify({"detail": "Envie um objeto JSON"}), 400
        try:
            model = AtualizarProfileService.executar(current_user["id"], dados)
            return jsonify(model.to_dict()), 200
        except ProfileFieldProtectedError as e:
            return jsonify({'detail': str(e)}), 400
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar_me():
        current_user = get_current_user()
        if not current_user:
            return jsonify({"detail": "Não autorizado"}), 401
        try:
            DeletarProfileService.executar(current_user["id"])
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    @login_required
    def deletar(id):
        if id != g.current_user["id"]:
            return jsonify({"detail": "Perfil não encontrado"}), 404
        try:
            DeletarProfileService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
