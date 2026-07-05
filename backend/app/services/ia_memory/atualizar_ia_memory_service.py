from app.models.ia_memory import IaMemory

class AtualizarIaMemoryService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = IaMemory.buscar_por_id(id)
        if not model:
            raise ValueError(f"IaMemory com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
