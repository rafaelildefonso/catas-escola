from app.models.browser_session import BrowserSession

class AtualizarBrowserSessionService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = BrowserSession.buscar_por_id(id)
        if not model:
            raise ValueError(f"BrowserSession com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
