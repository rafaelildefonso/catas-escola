from models.page_context import PageContext

class ListarPageContextsService:
    @staticmethod
    def executar():
        return PageContext.listar_todos()
