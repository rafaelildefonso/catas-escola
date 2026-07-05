from app.models.automation_step_log import AutomationStepLog

class BuscarAutomationStepLogService:
    @staticmethod
    def executar(id):
        model = AutomationStepLog.buscar_por_id(id)
        if not model:
            raise ValueError(f"AutomationStepLog com id {id} nao encontrado")
        return model
