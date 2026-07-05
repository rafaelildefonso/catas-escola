from app.models.execution_log import ExecutionLog

class CriarExecutionLogService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = ExecutionLog(**dados)
        model.salvar()
        return model
