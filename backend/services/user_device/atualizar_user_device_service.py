from models.user_device import UserDevice

class AtualizarUserDeviceService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = UserDevice.buscar_por_id(id)
        if not model:
            raise ValueError(f"UserDevice com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
