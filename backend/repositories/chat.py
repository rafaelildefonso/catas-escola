from services.db_supabase import supabase
from datetime import datetime
from typing import Optional, List, Dict



def _require_data(response, context: str):
    data = getattr(response, "data", None)
    if data is None:
        raise RuntimeError(f"Resposta Supabase inválida ao {context} (sem data)")
    return data

def create_session(user_id: str, title: Optional[str] = None, is_onboarding: bool = False) -> Dict:
    """
    Cria uma nova sessão de chat para o usuário.
    
    Args:
        user_id: ID do usuário
        title: Título da sessão (opcional, padrão: "Nova Conversa")
        is_onboarding: Se é uma sessão de onboarding (padrão: False)
    
    Returns:
        Dicionário com os dados da sessão criada
    """
    # Dev-user bypass: return fake session without hitting DB
    if user_id.startswith("dev-user-"):
        return {
            "id": f"dev-session-{user_id}",
            "user_id": user_id,
            "title": title or "Nova Conversa",
            "is_onboarding": is_onboarding,
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat()
        }
    
    session_data = {
        "user_id": user_id,
        "title": title or "Nova Conversa",
        "is_onboarding": is_onboarding,
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat()
    }
    
    try:
        response = (
            supabase.table("chat_sessions").insert(session_data).execute()
        )
        data = _require_data(response, "criar sessão")
        if not data or len(data) == 0:
            raise RuntimeError("Sessão criada mas nenhum dado retornado")
        return data[0]
    except Exception as e:
        raise RuntimeError(f"Erro ao criar sessão: {e}")


def get_user_sessions(user_id: str, limit: int = 50, offset: int = 0) -> List[Dict]:
    """
    Lista todas as sessões de chat do usuário, ordenadas por updated_at (mais recentes primeiro).
    
    Args:
        user_id: ID do usuário
        limit: Número máximo de sessões a retornar
        offset: Número de registros para pular (paginação)
    
    Returns:
        Lista de sessões
    """
    try:
        response = (
            supabase.table("chat_sessions")
            .select("*")
            .eq("user_id", user_id)
            .order("updated_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )
        data = _require_data(response, "buscar sessões")
        return data or []
    except Exception as e:
        raise RuntimeError(f"Erro ao buscar sessões: {e}")


def get_session(session_id: str, user_id: str) -> Optional[Dict]:
    """
    Busca uma sessão específica, garantindo que pertence ao usuário.
    """
    # Dev-user bypass: return fake session if it's a dev session ID
    if session_id and session_id.startswith("dev-session-"):
        # Extract user_id from session_id (format: dev-session-{user_id})
        if "-" in session_id:
            parts = session_id.split("-")
            if len(parts) >= 3 and parts[0] == "dev" and parts[1] == "session":
                extracted_user_id = "-".join(parts[2:])  # Get everything after "dev-session-"
                if extracted_user_id.startswith("dev-user-"):
                    return {
                        "id": session_id,
                        "user_id": extracted_user_id,
                        "title": "Nova Conversa",
                        "is_onboarding": False,
                        "created_at": datetime.utcnow().isoformat(),
                        "updated_at": datetime.utcnow().isoformat()
                    }
    
    try:
        response = (
            supabase
            .table("chat_sessions")
            .select("*")
            .eq("id", session_id)
            .eq("user_id", user_id)
            .execute()
        )
    except Exception:
        return None

    data = _require_data(response, "buscar sessão")
    if not data or len(data) == 0:
        return None
    return data[0]


def get_session_messages(session_id: str, user_id: str, limit: int = 100, offset: int = 0) -> List[Dict]:
    """
    Busca todas as mensagens de uma sessão, garantindo que a sessão pertence ao usuário.
    Ordenadas por created_at (mais antigas primeiro).
    
    Args:
        session_id: ID da sessão
        user_id: ID do usuário (para validação de segurança)
        limit: Número máximo de mensagens a retornar
        offset: Número de registros para pular
    
    Returns:
        Lista de mensagens
    """
    # Primeiro verificar se a sessão pertence ao usuário
    session = get_session(session_id, user_id)
    if not session:
        raise ValueError(f"Sessão {session_id} não encontrada ou não pertence ao usuário")
    
    # Buscar mensagens
    try:
        response = (
            supabase.table("messages")
            .select("*")
            .eq("session_id", session_id)
            .order("created_at", desc=False)  # Mais antigas primeiro
            .range(offset, offset + limit - 1)
            .execute()
        )
        data = _require_data(response, "buscar mensagens")
        return data or []
    except Exception as e:
        raise RuntimeError(f"Erro ao buscar mensagens: {e}")


def save_message(
    session_id: str,
    role: str,
    content: str,
    metadata: Optional[Dict] = None
) -> Dict:
    """
    Salva uma mensagem no banco de dados.
    
    Args:
        session_id: ID da sessão
        role: Papel da mensagem ('user', 'assistant', 'system')
        content: Conteúdo da mensagem
        metadata: Metadados adicionais (ex: action_details)
    
    Returns:
        Dados da mensagem salva
    """
    if role not in ['user', 'assistant', 'system']:
        raise ValueError(f"Role inválido: {role}. Deve ser 'user', 'assistant' ou 'system'")
    
    message_data = {
        "session_id": session_id,
        "role": role,
        "content": content,
        "metadata": metadata or {},
        "created_at": datetime.utcnow().isoformat()
    }
    
    try:
        response = (
            supabase.table("messages").insert(message_data).execute()
        )
        data = _require_data(response, "salvar mensagem")
        if not data or len(data) == 0:
            raise RuntimeError("Mensagem salva mas nenhum dado retornado")
    except Exception as e:
        raise RuntimeError(f"Erro ao salvar mensagem: {e}")
    
    # Atualizar updated_at da sessão
    update_session_updated_at(session_id)
    
    return data[0]


def update_message(
    message_id: str,
    content: Optional[str] = None,
    metadata: Optional[Dict] = None
) -> Dict:
    """
    Atualiza o conteúdo e/ou metadata de uma mensagem existente.
    Usado para Respostas Contínuas (Human-in-the-Loop).
    
    Args:
        message_id: ID da mensagem
        content: Novo conteúdo (opcional)
        metadata: Novos metadados para fazer merge (opcional)
    
    Returns:
        Dados da mensagem atualizada
    """
    update_data = {}
    if content is not None:
        update_data["content"] = content
    
    # Se houver metadata, precisamos buscar a anterior e fazer merge ou apenas atualizar
    # Para CATAS, vamos fazer merge para não perder campos como action_details
    if metadata is not None:
        try:
            # Buscar metadata atual
            existing = supabase.table("messages").select("metadata").eq("id", message_id).execute()
            existing_data = _require_data(existing, "buscar metadata para update")
            
            current_metadata = {}
            if existing_data and len(existing_data) > 0:
                current_metadata = existing_data[0].get("metadata") or {}
            
            # Merge
            current_metadata.update(metadata)
            update_data["metadata"] = current_metadata
        except Exception as e:
            print(f"⚠️ Erro ao fazer merge de metadata: {e}")
            update_data["metadata"] = metadata # Fallback: sobrescrever

    try:
        response = (
            supabase.table("messages")
            .update(update_data)
            .eq("id", message_id)
            .execute()
        )
        data = _require_data(response, "atualizar mensagem")
        if not data or len(data) == 0:
            raise RuntimeError("Mensagem atualizada mas nenhum dado retornado")
        return data[0]
    except Exception as e:
        raise RuntimeError(f"Erro ao atualizar mensagem: {e}")


def update_session_title(session_id: str, user_id: str, title: str) -> Dict:
    """
    Atualiza o título de uma sessão.
    
    Args:
        session_id: ID da sessão
        user_id: ID do usuário (para validação de segurança)
        title: Novo título
    
    Returns:
        Dados da sessão atualizada
    """
    # Verificar se a sessão pertence ao usuário
    session = get_session(session_id, user_id)
    if not session:
        raise ValueError(f"Sessão {session_id} não encontrada ou não pertence ao usuário")
    
    try:
        response = (
            supabase.table("chat_sessions")
            .update({
                "title": title,
                "updated_at": datetime.utcnow().isoformat()
            })
            .eq("id", session_id)
            .eq("user_id", user_id)
            .execute()
        )
        data = _require_data(response, "atualizar título")
        if not data or len(data) == 0:
            raise RuntimeError("Título atualizado mas nenhum dado retornado")
        return data[0]
    except Exception as e:
        raise RuntimeError(f"Erro ao atualizar título: {e}")


def update_session_updated_at(session_id: str):
    """
    Atualiza o campo updated_at de uma sessão (usado internamente quando uma mensagem é salva).
    
    Args:
        session_id: ID da sessão
    """
    try:
        supabase.table("chat_sessions").update(
            {"updated_at": datetime.utcnow().isoformat()}
        ).eq("id", session_id).execute()
    except Exception as e:
        print(f"⚠️ Aviso: Erro ao atualizar updated_at da sessão {session_id}: {e}")


def delete_session(session_id: str, user_id: str) -> bool:
    """
    Deleta uma sessão e todas as suas mensagens (CASCADE).
    
    Args:
        session_id: ID da sessão
        user_id: ID do usuário (para validação de segurança)
    
    Returns:
        True se deletado com sucesso
    """
    # Verificar se a sessão pertence ao usuário
    session = get_session(session_id, user_id)
    if not session:
        raise ValueError(f"Sessão {session_id} não encontrada ou não pertence ao usuário")
    
    try:
        supabase.table("chat_sessions").delete().eq("id", session_id).eq(
            "user_id", user_id
        ).execute()
        return True
    except Exception as e:
        raise RuntimeError(f"Erro ao deletar sessão: {e}")

def is_session_onboarding(session_id: str, user_id: str) -> bool:
    """
    Verifica se a sessão é a sessão de onboarding via flag is_onboarding no banco.
    """
    try:
        session = get_session(session_id, user_id)
        return session.get("is_onboarding", False) if session else False
    except Exception:
        return False


def insert_message(
    session_id: str,
    role: str,
    content: str,
    metadata: Optional[Dict] = None
) -> Dict:
    """
    Insere uma mensagem no banco de dados (usado pelo workflow para mensagens de completion).
    Não atualiza o updated_at da sessão.

    Args:
        session_id: ID da sessão
        role: Papel da mensagem ('user', 'assistant', 'system')
        content: Conteúdo da mensagem
        metadata: Metadados adicionais

    Returns:
        Dados da mensagem inserida
    """
    if role not in ['user', 'assistant', 'system']:
        raise ValueError(f"Role inválido: {role}. Deve ser 'user', 'assistant' ou 'system'")

    message_data = {
        "session_id": session_id,
        "role": role,
        "content": content,
        "metadata": metadata or {},
        "created_at": datetime.utcnow().isoformat()
    }

    try:
        response = (
            supabase.table("messages").insert(message_data).execute()
        )
        data = _require_data(response, "inserir mensagem")
        if not data or len(data) == 0:
            raise RuntimeError("Mensagem inserida mas nenhum dado retornado")
        return data[0]
    except Exception as e:
        raise RuntimeError(f"Erro ao inserir mensagem: {e}")
