from app.models.execution_log import ExecutionLog

class DeletarExecutionLogService:
    @staticmethod
    def executar(id):
        model = ExecutionLog.buscar_por_id(id)
        if not model:
            raise ValueError(f"ExecutionLog com id {id} nao encontrado")
        model.deletar()
        return None
