import math
import logging
from typing import Dict, Any
from core.config import settings
from services.db_supabase import supabase
from services.notification_service import notification_service

logger = logging.getLogger(__name__)

class CreditService:
    @staticmethod
    def calculate_credits(tokens: int) -> int:
        """
        Converte tokens em créditos baseados na configuração TOKENS_PER_CREDIT.
        Custo mínimo é 1 crédito se houver uso de tokens.
        """
        if tokens <= 0:
            return 0
        return max(1, math.ceil(tokens / settings.TOKENS_PER_CREDIT))

    @staticmethod
    def debit_credits(user_id: str, amount: int, idempotency_key: str = None) -> Dict[str, Any]:
        """
        Chama o RPC atômico no Postgres para debitar créditos.
        Lida com quota mensal and pool of rollover.
        """
        # Dev-user bypass: return success without hitting DB
        if user_id.startswith("dev-user-"):
            return {"status": "success", "amount_debited": amount, "new_balance": 0}
        
        if amount <= 0:
            return {"status": "success", "amount_debited": 0}

        try:
            # Observação: Supabase RPC espera UUID se o parâmetro for UUID no Postgres
            payload = {"p_user_id": user_id, "p_amount": int(amount)}
            if idempotency_key:
                payload["p_idempotency_key"] = idempotency_key

            response = supabase.rpc(
                "handle_credit_debit",
                payload
            ).execute()

            if not response.data:
                return {"status": "error", "message": "No data returned from RPC"}

            result = response.data
            if result.get("status") == "success":
                logger.info(f"📊 [Credits] User {user_id} debited {amount} credits. Status: {result.get('status')}")
                # Verificar se o saldo está baixo após o débito
                CreditService.check_low_balance(user_id, result)
            
            return result
        except Exception as e:
            logger.error(f"❌ CreditService Error: {e}")
            return {"status": "error", "message": str(e)}

    @staticmethod
    def check_low_balance(user_id: str, balance_info: Dict[str, Any]):
        """
        Dispara uma notificação se o saldo total estiver abaixo de 20% do limite mensal.
        """
        monthly_used = balance_info.get("new_monthly_used", 0)
        monthly_limit = balance_info.get("monthly_limit", 1)
        rollover_balance = balance_info.get("new_rollover_balance", 0)
        
        monthly_remaining = max(0, monthly_limit - monthly_used)
        total_remaining = monthly_remaining + rollover_balance
        
        # Disparar em 20% do limite mensal
        threshold = monthly_limit * 0.2
        
        # Só notificar se estiver realmente baixo e não tivermos notificado recentemente 
        # (Idealmente teríamos um flag de 'last_notified_low_balance' no profile)
        if total_remaining <= threshold and total_remaining > 0:
            try:
                notification_service.send_notification(
                    user_id=user_id,
                    title="Créditos quase acabando! ⚡",
                    body=f"Seu saldo total é de {total_remaining} créditos. Evite que suas automações parem, recarregue agora.",
                    data={"type": "billing", "action": "upgrade_plan"}
                )
            except Exception as e:
                logger.warning(f"⚠️ Failed to send low balance notification: {e}")

    @staticmethod
    def calculate_rollover(quota_used: int, quota_limit: int, current_rollover: int) -> int:
        """
        Calcula quanto de crédito pode ser movido para o rollover no reset mensal.
        Obedece o limite de settings.MAX_ROLLOVER_MULTIPLIER.
        Se o uso for maior que a cota (quota_used > quota_limit), o excedente é subtraído do rollover.
        """
        unused = quota_limit - quota_used
        new_rollover_pool = current_rollover + unused
        
        # O rollover nunca pode ser negativo
        new_rollover_pool = max(0, new_rollover_pool)
        
        # Existe um teto para o rollover acumulado (geralmente 3x a cota mensal)
        max_allowed = quota_limit * settings.MAX_ROLLOVER_MULTIPLIER
        
        return min(new_rollover_pool, max_allowed)

# Singleton instance
credit_service = CreditService()
