from app.models.message import Message

class DeletarMessageService:
    @staticmethod
    def executar(id):
        model = Message.buscar_por_id(id)
        if not model:
            raise ValueError(f"Message com id {id} nao encontrado")
        model.deletar()
        return None
