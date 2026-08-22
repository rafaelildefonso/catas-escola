from flask import request, jsonify
from services.user.criar_user_service import CriarUserService
from services.user.listar_users_service import ListarUsersService
from services.user.buscar_user_service import BuscarUserService
from services.user.atualizar_user_service import AtualizarUserService
from services.user.deletar_user_service import DeletarUserService


class UserController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarUserService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarUsersService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarUserService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarUserService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarUserService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404