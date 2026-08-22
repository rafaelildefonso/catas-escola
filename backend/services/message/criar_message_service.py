from models.message import Message

class CriarMessageService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = Message(**dados)
        model.salvar()
        return model
