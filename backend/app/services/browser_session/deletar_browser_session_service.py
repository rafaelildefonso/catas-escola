from app.models.browser_session import BrowserSession

class DeletarBrowserSessionService:
    @staticmethod
    def executar(id):
        model = BrowserSession.buscar_por_id(id)
        if not model:
            raise ValueError(f"BrowserSession com id {id} nao encontrado")
        model.deletar()
        return None
