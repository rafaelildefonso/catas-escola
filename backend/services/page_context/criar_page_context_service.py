from models.page_context import PageContext

class CriarPageContextService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = PageContext(**dados)
        model.salvar()
        return model
