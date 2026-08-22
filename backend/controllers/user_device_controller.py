from flask import request, jsonify
from services.user_device.criar_user_device_service import CriarUserDeviceService
from services.user_device.listar_user_devices_service import ListarUserDevicesService
from services.user_device.buscar_user_device_service import BuscarUserDeviceService
from services.user_device.atualizar_user_device_service import AtualizarUserDeviceService
from services.user_device.deletar_user_device_service import DeletarUserDeviceService


class UserDeviceController:

    @staticmethod
    def criar():
        dados = request.get_json(silent=True)
        try:
            model = CriarUserDeviceService.executar(dados)
            return jsonify(model.to_dict()), 201
        except ValueError as e:
            return jsonify({'detail': str(e)}), 400

    @staticmethod
    def listar():
        models = ListarUserDevicesService.executar()
        return jsonify([m.to_dict() for m in models]), 200

    @staticmethod
    def buscar_por_id(id):
        try:
            model = BuscarUserDeviceService.executar(id)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def atualizar(id):
        dados = request.get_json(silent=True)
        try:
            model = AtualizarUserDeviceService.executar(id, dados)
            return jsonify(model.to_dict()), 200
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404

    @staticmethod
    def deletar(id):
        try:
            DeletarUserDeviceService.executar(id)
            return '', 204
        except ValueError as e:
            return jsonify({'detail': str(e)}), 404
