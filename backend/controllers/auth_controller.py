from flask import request, jsonify

from services.auth.criar_conta_service import CriarContaService
from services.auth.autenticar_usuario_service import AutenticarUsuarioService, AutenticacaoError
from services.auth.obter_conta_service import ObterContaService
from services.user.criar_user_service import EmailJaCadastradoError
from core.security import get_current_user


class AuthController:

    @staticmethod
    def signup():
        dados = request.get_json(silent=True) or {}
        try:
            conta = CriarContaService.executar(dados)
            return jsonify({
                "token": conta["token"],
                "user": conta["user"].to_dict(),
                "profile": conta["profile"].to_dict(),
            }), 201
        except EmailJaCadastradoError as e:
            return jsonify({"detail": str(e)}), 409
        except ValueError as e:
            return jsonify({"detail": str(e)}), 400

    @staticmethod
    def login():
        dados = request.get_json(silent=True) or {}
        try:
            conta = AutenticarUsuarioService.executar(dados)
            return jsonify({
                "token": conta["token"],
                "user": conta["user"].to_dict(),
                "profile": conta["profile"].to_dict(),
            })
        except AutenticacaoError as e:
            return jsonify({"detail": str(e)}), e.status_code

    @staticmethod
    def me():
        current_user = get_current_user()
        if not current_user:
            return jsonify({"detail": "Não autorizado"}), 401
        try:
            conta = ObterContaService.executar(current_user["id"])
            return jsonify({
                "user": conta["user"].to_dict(),
                "profile": conta["profile"].to_dict(),
            })
        except ValueError as e:
            return jsonify({"detail": str(e)}), 404