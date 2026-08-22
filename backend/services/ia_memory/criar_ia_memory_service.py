from models.ia_memory import IaMemory

class CriarIaMemoryService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = IaMemory(**dados)
        model.salvar()
        return model
