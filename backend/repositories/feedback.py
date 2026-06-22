from services.db_supabase import supabase
from datetime import datetime
from typing import Dict, Optional


def upsert_feedback(
    message_id: str,
    user_id: str,
    session_id: str,
    is_liked: bool,
    reason: Optional[str] = None,
) -> Dict:
    """
    Cria ou atualiza o feedback de uma mensagem (like/dislike).

    Usa upsert com conflict na combinação (message_id, user_id), portanto:
    - Se ainda não há feedback → INSERT
    - Se já existe → UPDATE (troca like/dislike)

    Args:
        message_id: ID da mensagem na tabela `messages`
        user_id:    ID do usuário autenticado
        session_id: ID da sessão (para analytics)
        is_liked:   True = like, False = dislike
        reason:     Motivo do feedback (opcional)

    Returns:
        Dados do registro salvo
    """
    payload = {
        "message_id": message_id,
        "user_id":    user_id,
        "session_id": session_id,
        "is_liked":   is_liked,
        "updated_at": datetime.utcnow().isoformat(),
    }

    # Adiciona reason apenas se for fornecido
    if reason is not None:
        payload["reason"] = reason

    try:
        response = (
            supabase
            .table("message_feedback")
            .upsert(payload, on_conflict="message_id,user_id")
            .execute()
        )
        data = response.data
        if not data:
            raise RuntimeError("Upsert retornou sem dados")
        return data[0]
    except Exception as e:
        raise RuntimeError(f"Erro ao salvar feedback: {e}")


def delete_feedback(message_id: str, user_id: str) -> bool:
    """
    Remove o feedback de uma mensagem (desfaz like/dislike).

    Args:
        message_id: ID da mensagem
        user_id:    ID do usuário

    Returns:
        True se deletado com sucesso
    """
    try:
        supabase.table("message_feedback").delete().eq(
            "message_id", message_id
        ).eq("user_id", user_id).execute()
        return True
    except Exception as e:
        raise RuntimeError(f"Erro ao remover feedback: {e}")


def get_feedback_summary(session_id: str) -> Dict:
    """
    Retorna um resumo dos feedbacks de uma sessão.
    Útil para analytics e para o backend de IA aprender preferências.

    Args:
        session_id: ID da sessão

    Returns:
        {"total": int, "likes": int, "dislikes": int}
    """
    try:
        response = (
            supabase
            .table("message_feedback")
            .select("is_liked")
            .eq("session_id", session_id)
            .execute()
        )
        rows = response.data or []
        likes    = sum(1 for r in rows if r["is_liked"] is True)
        dislikes = sum(1 for r in rows if r["is_liked"] is False)
        return {"total": len(rows), "likes": likes, "dislikes": dislikes}
    except Exception as e:
        raise RuntimeError(f"Erro ao buscar resumo de feedback: {e}")

def get_recent_liked_messages(user_id: str, limit: int = 3) -> list[str]:
    """
    Busca os textos das últimas N mensagens que o usuário marcou com "LIKE" (is_liked=True).
    Usado para injetar estilo e preferências de sucesso no prompt da IA.
    """
    try:
        response = (
            supabase
            .table("message_feedback")
            .select("message_id, messages(content)")
            .eq("user_id", user_id)
            .eq("is_liked", True)
            .order("updated_at", desc=True)
            .limit(limit)
            .execute()
        )
        rows = response.data or []
        
        liked_texts = []
        for row in rows:
            # Pega o conteúdo dependendo de como o Supabase retorna o join
            msg_obj = row.get("messages")
            if isinstance(msg_obj, dict):
                content = msg_obj.get("content")
                if content:
                    liked_texts.append(content)
            elif isinstance(msg_obj, list) and len(msg_obj) > 0:
                content = msg_obj[0].get("content")
                if content:
                    liked_texts.append(content)
                    
        return liked_texts
    except Exception as e:
        print(f"⚠️ Erro ao buscar feedbacks positivos para RAG: {e}")
        return []


def get_user_preferences_summary(user_id: str) -> Dict[str, int]:
    """
    Calcula um resumo das preferências do usuário baseado nos reasons do feedback.
    Retorna contagem de cada tipo de feedback (positivo e negativo).
    Usado para injetar preferências sutis no prompt da IA.
    """
    try:
        response = (
            supabase
            .table("message_feedback")
            .select("is_liked, reason")
            .eq("user_id", user_id)
            .execute()
        )
        rows = response.data or []

        positive_reasons = {}
        negative_reasons = {}

        for row in rows:
            is_liked = row.get("is_liked")
            reason = row.get("reason")

            if is_liked is True and reason:
                positive_reasons[reason] = positive_reasons.get(reason, 0) + 1
            elif is_liked is False and reason:
                negative_reasons[reason] = negative_reasons.get(reason, 0) + 1

        return {
            "positive": positive_reasons,
            "negative": negative_reasons,
            "total": len(rows),
        }
    except Exception as e:
        print(f"⚠️ Erro ao buscar preferências do usuário: {e}")
        return {"positive": {}, "negative": {}, "total": 0}
