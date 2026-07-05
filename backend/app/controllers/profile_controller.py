from flask import request, jsonify
from app.services.profile.criar_profile_service import CriarProfileService
from app.services.profile.listar_profiles_service import ListarProfilesService
from app.services.profile.buscar_profile_service import BuscarProfileService
from app.services.profile.atualizar_profile_service import AtualizarProfileService
from app.services.profile.deletar_profile_service import DeletarProfileService


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
    def deletar(id):
        try:
            DeletarProfileService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
