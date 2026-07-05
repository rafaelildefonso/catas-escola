from app.models.browser_session import BrowserSession

class CriarBrowserSessionService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = BrowserSession(**dados)
        model.salvar()
        return model
