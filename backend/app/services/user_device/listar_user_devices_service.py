from app.models.user_device import UserDevice

class ListarUserDevicesService:
    @staticmethod
    def executar():
        return UserDevice.listar_todos()
