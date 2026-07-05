from app.models.execution_log import ExecutionLog

class AtualizarExecutionLogService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = ExecutionLog.buscar_por_id(id)
        if not model:
            raise ValueError(f"ExecutionLog com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
