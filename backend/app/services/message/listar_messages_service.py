from app.models.message import Message

class ListarMessagesService:
    @staticmethod
    def executar():
        return Message.listar_todos()
