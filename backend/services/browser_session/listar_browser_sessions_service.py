from models.browser_session import BrowserSession

class ListarBrowserSessionsService:
    @staticmethod
    def executar():
        return BrowserSession.listar_todos()
