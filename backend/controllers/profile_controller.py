from flask import request, jsonify
from services.profile.criar_profile_service import CriarProfileService
from services.profile.listar_profiles_service import ListarProfilesService
from services.profile.buscar_profile_service import BuscarProfileService
from services.profile.atualizar_profile_service import AtualizarProfileService
from services.profile.deletar_profile_service import DeletarProfileService
from core.security import get_current_user


class ProfileController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarProfileService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarProfilesService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarProfileService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarProfileService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar_me():
        current_user = get_current_user()
        if not current_user:
            return jsonify({"detail": "Não autorizado"}), 401
        dados = request.get_json(silent=True)
        try:
            model = AtualizarProfileService.executar(current_user["id"], dados)
            return jsonify(model.to_dict()), 200
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
    def deletar(id):
        try:
            DeletarProfileService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
