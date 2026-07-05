from app.models.user_device import UserDevice

class BuscarUserDeviceService:
    @staticmethod
    def executar(id):
        model = UserDevice.buscar_por_id(id)
        if not model:
            raise ValueError(f"UserDevice com id {id} nao encontrado")
        return model
