from services.db_supabase import supabase
from datetime import datetime
from typing import Optional, List, Dict

def log_automation(
    user_id: str,
    workflow_name: Optional[str] = None,
    status: str = 'running',
    input_data: Optional[Dict] = None,
    suggestion_id: Optional[str] = None,
    session_id: Optional[str] = None,
    result_data: Optional[Dict] = None
) -> Dict:
    """
    Salva um log de execução no banco de dados (tabela execution_logs).
    """
    if status not in ['success', 'failed', 'running']:
        raise ValueError(f"Status inválido: {status}. Deve ser 'success', 'failed' ou 'running'")
    
    log_data = {
        "user_id": user_id,
        "workflow_name": workflow_name,
        "status": status,
        "input_data": input_data,
        "result_data": result_data,
        "suggestion_id": suggestion_id,
        "session_id": session_id,
        "started_at": datetime.utcnow().isoformat()
    }
    
    response = (
        supabase
        .table("execution_logs")
        .insert(log_data)
        .execute()
    )
    
    return response.data[0]

def get_user_execution_logs(user_id: str, limit: int = 50) -> List[Dict]:
    """
    Lista os logs de execução do usuário.
    """
    response = (
        supabase
        .table("execution_logs")
        .select("*")
        .eq("user_id", user_id)
        .order("started_at", desc=True)
        .limit(limit)
        .execute()
    )
    
    return response.data or []

def update_execution_log(
    log_id: str,
    status: str,
    result_data: Optional[Dict] = None,
    error_message: Optional[str] = None
) -> Dict:
    """
    Atualiza um log de execução finalizado.
    """
    update_data = {
        "status": status,
        "finished_at": datetime.utcnow().isoformat()
    }
    
    if result_data:
        update_data["result_data"] = result_data
    if error_message:
        update_data["error_message"] = error_message
    
    response = (
        supabase
        .table("execution_logs")
        .update(update_data)
        .eq("id", log_id)
        .execute()
    )
    
    return response.data[0]
