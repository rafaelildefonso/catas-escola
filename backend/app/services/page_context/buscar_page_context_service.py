from app.models.page_context import PageContext

class BuscarPageContextService:
    @staticmethod
    def executar(id):
        model = PageContext.buscar_por_id(id)
        if not model:
            raise ValueError(f"PageContext com id {id} nao encontrado")
        return model
