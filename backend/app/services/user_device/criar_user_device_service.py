from app.models.user_device import UserDevice

class CriarUserDeviceService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = UserDevice(**dados)
        model.salvar()
        return model
