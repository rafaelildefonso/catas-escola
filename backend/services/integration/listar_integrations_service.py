from models.integration import Integration

class ListarIntegrationsService:
    @staticmethod
    def executar():
        return Integration.listar_todos()
