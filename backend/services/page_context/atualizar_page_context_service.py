from models.page_context import PageContext

class AtualizarPageContextService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = PageContext.buscar_por_id(id)
        if not model:
            raise ValueError(f"PageContext com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
