from models.automation import Automation

class ListarAutomationsService:
    @staticmethod
    def executar():
        return Automation.listar_todos()
