from app.models.ia_memory import IaMemory

class DeletarIaMemoryService:
    @staticmethod
    def executar(id):
        model = IaMemory.buscar_por_id(id)
        if not model:
            raise ValueError(f"IaMemory com id {id} nao encontrado")
        model.deletar()
        return None
