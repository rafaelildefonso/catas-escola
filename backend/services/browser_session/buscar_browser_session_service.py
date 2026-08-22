from models.browser_session import BrowserSession

class BuscarBrowserSessionService:
    @staticmethod
    def executar(id):
        model = BrowserSession.buscar_por_id(id)
        if not model:
            raise ValueError(f"BrowserSession com id {id} nao encontrado")
        return model
