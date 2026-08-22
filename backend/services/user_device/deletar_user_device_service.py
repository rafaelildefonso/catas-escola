from models.user_device import UserDevice

class DeletarUserDeviceService:
    @staticmethod
    def executar(id):
        model = UserDevice.buscar_por_id(id)
        if not model:
            raise ValueError(f"UserDevice com id {id} nao encontrado")
        model.deletar()
        return None
