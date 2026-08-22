from models.execution_log import ExecutionLog

class BuscarExecutionLogService:
    @staticmethod
    def executar(id):
        model = ExecutionLog.buscar_por_id(id)
        if not model:
            raise ValueError(f"ExecutionLog com id {id} nao encontrado")
        return model
