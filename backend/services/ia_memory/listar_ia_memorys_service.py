from models.ia_memory import IaMemory

class ListarIaMemorysService:
    @staticmethod
    def executar():
        return IaMemory.listar_todos()
