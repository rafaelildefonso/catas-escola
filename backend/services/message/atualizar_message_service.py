from models.message import Message

class AtualizarMessageService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = Message.buscar_por_id(id)
        if not model:
            raise ValueError(f"Message com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
