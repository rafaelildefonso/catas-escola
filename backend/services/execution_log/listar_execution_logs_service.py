from models.execution_log import ExecutionLog

class ListarExecutionLogsService:
    @staticmethod
    def executar():
        return ExecutionLog.listar_todos()
