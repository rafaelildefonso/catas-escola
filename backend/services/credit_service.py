import math
import logging
from typing import Dict, Any
from core.config import settings
from services.database import get_sync_db
from models.db_models import Profile
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
        Debita créditos do usuário de forma atômica.
        Lida com quota mensal e pool de rollover.
        """
        # Dev-user bypass: return success without hitting DB
        if user_id.startswith("dev-user-"):
            return {"status": "success", "amount_debited": amount, "new_balance": 0}
        
        if amount <= 0:
            return {"status": "success", "amount_debited": 0}

        db = get_sync_db()
        try:
            profile = (
                db.query(Profile)
                .filter(Profile.id == user_id)
                .with_for_update()
                .first()
            )

            if not profile:
                return {"status": "error", "message": "User profile not found"}

            v_monthly_limit = profile.monthly_quota_limit or 500
            v_monthly_remaining = max(0, v_monthly_limit - profile.quota_used)

            if v_monthly_remaining >= amount:
                v_deduct_from_monthly = amount
                v_deduct_from_rollover = 0
            else:
                v_deduct_from_monthly = v_monthly_remaining
                v_deduct_from_rollover = amount - v_monthly_remaining

            total_available = v_monthly_remaining + (profile.rollover_credits or 0)
            if total_available < amount:
                return {
                    "status": "error",
                    "message": "Insufficient credits",
                    "monthly_remaining": v_monthly_remaining,
                    "rollover_available": profile.rollover_credits or 0,
                    "requested": amount,
                }

            new_monthly_used = profile.quota_used + v_deduct_from_monthly
            new_rollover_balance = max(0, (profile.rollover_credits or 0) - v_deduct_from_rollover)

            profile.quota_used = new_monthly_used
            profile.rollover_credits = new_rollover_balance
            db.flush()

            result = {
                "status": "success",
                "amount_debited": amount,
                "deducted_from_monthly": v_deduct_from_monthly,
                "deducted_from_rollover": v_deduct_from_rollover,
                "new_monthly_used": new_monthly_used,
                "monthly_limit": v_monthly_limit,
                "new_rollover_balance": new_rollover_balance,
            }

            logger.info(f"📊 [Credits] User {user_id} debited {amount} credits. Status: success")
            CreditService.check_low_balance(user_id, result)

            return result
        except Exception as e:
            logger.error(f"❌ CreditService Error: {e}")
            return {"status": "error", "message": str(e)}
        finally:
            db.close()

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
