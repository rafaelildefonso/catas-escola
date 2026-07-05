from app.models.ia_memory import IaMemory

class BuscarIaMemoryService:
    @staticmethod
    def executar(id):
        model = IaMemory.buscar_por_id(id)
        if not model:
            raise ValueError(f"IaMemory com id {id} nao encontrado")
        return model
