from services.db_supabase import supabase
from datetime import datetime, date
from typing import Optional, Dict, Tuple
from services.credit_service import credit_service

def get_user_profile(user_id: str) -> Optional[Dict]:
    """
    Busca o perfil do usuário na tabela profiles.
    Retorna None se o user_id não for um UUID válido (ex: dev-token).
    """
    import uuid as uuid_lib
    try:
        uuid_lib.UUID(str(user_id))
    except (ValueError, TypeError):
        return None

    try:
        response = (
            supabase
            .table("profiles")
            .select("*")
            .eq("id", user_id)
            .execute()
        )
    except Exception:
        return None

    if response.data and len(response.data) > 0:
        return response.data[0]
    return None

def get_quota_config(tier: str) -> Dict:
    """
    Retorna a configuração de cota para uma tier específica.
    """
    configs = {
        "basic": {"limit": 500, "models": ["CATAS Basic"], "attachment_limit": 5},
        "pro": {"limit": 7500, "models": ["CATAS Basic", "CATAS Pro"], "attachment_limit": 100},
        "max": {"limit": 25000, "models": ["CATAS Basic", "CATAS Pro", "CATAS MAX"], "attachment_limit": 1000}
    }
    return configs.get(tier.lower(), configs["basic"])

def check_and_increment_quota(user_id: str, model_requested: Optional[str] = None) -> Tuple[bool, str, Dict]:
    """
    Verifica se o usuário tem cota disponível e se o modelo é permitido.
    Retorna (permitido, mensagem_erro, perfil)
    """
    profile = get_user_profile(user_id)

    if not profile:
        import uuid as uuid_lib
        try:
            uuid_lib.UUID(str(user_id))
            try:
                profile = create_default_profile(user_id)
            except Exception:
                # Fallback: perfil em memória se o insert falhar (FK, etc.)
                profile = {
                    "id": user_id,
                    "subscription_tier": "pro",
                    "quota_used": 0,
                    "rollover_credits": 0,
                    "monthly_quota_limit": 7500,
                    "last_quota_reset": datetime.utcnow().isoformat(),
                }
        except (ValueError, TypeError):
            profile = {
                "id": user_id,
                "subscription_tier": "pro",
                "quota_used": 0,
                "rollover_credits": 0,
                "monthly_quota_limit": 7500,
                "last_quota_reset": datetime.utcnow().isoformat(),
            }
    
    tier = profile.get("subscription_tier", "basic")
    config = get_quota_config(tier)
    
    # 1. Validar Modelo
    if model_requested and model_requested not in config["models"]:
        return False, f"O modelo {model_requested} não está disponível no seu plano {tier.capitalize()}.", profile

    # 2. Verificar se precisa resetar a cota (novo mês)
    last_reset = profile.get("last_quota_reset")
    today = date.today()
    
    should_reset = False
    if last_reset:
        last_reset_date = datetime.fromisoformat(last_reset.replace('Z', '+00:00')).date()
        # Resetar se for um mês diferente
        if last_reset_date.month != today.month or last_reset_date.year != today.year:
            should_reset = True
    else:
        should_reset = True

    if should_reset:
        # Lógica de Rollover Senior: Mover não usado para o pool de rollover
        quota_used = profile.get("quota_used", 0)
        quota_limit = profile.get("monthly_quota_limit") or config["limit"]
        current_rollover = profile.get("rollover_credits", 0)
        
        new_rollover = credit_service.calculate_rollover(quota_used, quota_limit, current_rollover)
        
        profile["quota_used"] = 0
        profile["rollover_credits"] = new_rollover
        profile["last_quota_reset"] = datetime.utcnow().isoformat()
        
        # Atualizar no banco imediatamente se for reset
        supabase.table("profiles").update({
            "quota_used": 0,
            "rollover_credits": new_rollover,
            "last_quota_reset": profile["last_quota_reset"]
        }).eq("id", user_id).execute()
    
    # 3. Verificar limite combinado (Mensal + Rollover)
    quota_limit = profile.get("monthly_quota_limit") or config["limit"]
    quota_used = profile.get("quota_used", 0)
    rollover_credits = profile.get("rollover_credits", 0)
    
    total_balance = (quota_limit - quota_used) + rollover_credits
    
    # Se o saldo total for 0 ou negativo, bloqueia
    if total_balance <= 0:
        return False, f"Seu saldo de {quota_limit} créditos acabou. Faça upgrade ou aguarde o próximo ciclo.", profile
    
    return True, "", profile

def increment_quota_usage(user_id: str, credits_to_add: int = 1) -> Dict:
    """
    Incrementa o uso da cota do usuário de forma atômica via CreditService.
    """
    result = credit_service.debit_credits(user_id, credits_to_add)
    
    if result.get("status") == "success":
        # Retornar o perfil atualizado para manter compatibilidade
        return get_user_profile(user_id)
    
    return get_user_profile(user_id) # Fallback

def create_default_profile(user_id: str) -> Dict:
    """
    Cria um perfil padrão para o usuário (basic tier).
    """
    default_profile = {
        "id": user_id,
        "subscription_tier": "basic",
        "quota_used": 0,
        "last_quota_reset": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat()
    }
    
    supabase.table("profiles").insert(default_profile).execute()
    
    return default_profile

def update_subscription_tier(user_id: str, tier: str) -> Optional[Dict]:
    """
    Atualiza o plano de assinatura do usuário após pagamento bem-sucedido no Stripe.
    Também reseta a cota utilizada para o novo período.
    """
    valid_plans = ["basic", "pro", "max"]
    tier = tier.lower()
    if tier not in valid_plans:
        tier = "basic"

    config = get_quota_config(tier)

    response = (
        supabase
        .table("profiles")
        .update({
            "subscription_tier": tier,
            "quota_used": 0, # Reset usage on upgrade/payment
            "monthly_quota_limit": config["limit"],
            "updated_at": datetime.utcnow().isoformat(),
        })
        .eq("id", user_id)
        .execute()
    )

    if response.data and len(response.data) > 0:
        print(f"[Stripe] User {user_id} plan updated to {tier.upper()} (quota limit: {config['limit']})")
        return response.data[0]

    print(f"[Stripe] WARNING: Could not find profile for user_id={user_id} to update tier.")
    return None

def update_profile_info(user_id: str, updates: Dict) -> Optional[Dict]:
    """
    Atualiza informações básicas do perfil (nome, etc).
    """
    response = (
        supabase
        .table("profiles")
        .update(updates)
        .eq("id", user_id)
        .execute()
    )
    
    if response.data and len(response.data) > 0:
        return response.data[0]
    return None

def delete_user_data(user_id: str):
    """
    Remove o perfil e dados associados do usuário.
    """
    # 1. Remover integrações
    supabase.table("integrations").delete().eq("user_id", user_id).execute()
    # 2. Remover o perfil
    supabase.table("profiles").delete().eq("id", user_id).execute()
    # Nota: O usuário de Auth deve ser removido via Admin API se necessário, 
    # mas aqui focamos nos dados do banco.
