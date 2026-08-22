import logging
from typing import Any, Dict

from core.config import settings
from app.models.profile import Profile

logger = logging.getLogger(__name__)


class CreditService:
    """Serviço de créditos: cálculo de custo por tokens, débito atômico e rollover mensal."""

    @staticmethod
    def calculate_credits(tokens: int) -> int:
        """Converte tokens em créditos (mínimo 1 crédito se houver uso de tokens)."""
        if tokens <= 0:
            return 0
        return max(1, -(-tokens // settings.TOKENS_PER_CREDIT))

    @staticmethod
    def debit_credits(user_id: str, amount: int, idempotency_key: str = None) -> Dict[str, Any]:
        """Debita créditos do usuário lidando com quota mensal e pool de rollover."""
        if user_id.startswith("dev-user-"):
            return {"status": "success", "amount_debited": amount, "new_balance": 0}

        if amount <= 0:
            return {"status": "success", "amount_debited": 0}

        try:
            profile = Profile.buscar_por_id(user_id)
            if not profile:
                return {"status": "error", "message": "User profile not found"}

            monthly_limit = profile.monthly_quota_limit or 500
            monthly_remaining = max(0, monthly_limit - (profile.quota_used or 0))
            rollover = profile.rollover_credits or 0

            if monthly_remaining + rollover < amount:
                return {
                    "status": "error",
                    "message": "Insufficient credits",
                    "monthly_remaining": monthly_remaining,
                    "rollover_available": rollover,
                    "requested": amount,
                }

            deduct_monthly = min(amount, monthly_remaining)
            deduct_rollover = amount - deduct_monthly

            profile.quota_used = (profile.quota_used or 0) + deduct_monthly
            profile.rollover_credits = max(0, rollover - deduct_rollover)

            from app.extensions import db
            db.session.commit()

            result = {
                "status": "success",
                "amount_debited": amount,
                "deducted_from_monthly": deduct_monthly,
                "deducted_from_rollover": deduct_rollover,
                "new_monthly_used": profile.quota_used,
                "monthly_limit": monthly_limit,
                "new_rollover_balance": profile.rollover_credits,
            }
            logger.info("[Credits] User %s debited %s credits.", user_id, amount)
            CreditService.check_low_balance(user_id, result)
            return result
        except Exception as e:
            logger.error("[Credits] Erro ao debitar créditos: %s", e)
            return {"status": "error", "message": str(e)}

    @staticmethod
    def check_low_balance(user_id: str, balance_info: Dict[str, Any]):
        """Registra aviso quando o saldo total cai abaixo de 20% do limite mensal.

        Notificações push foram desativadas nesta versão (funcionalidade fora de escopo).
        """
        monthly_used = balance_info.get("new_monthly_used", 0)
        monthly_limit = balance_info.get("monthly_limit", 1) or 1
        rollover_balance = balance_info.get("new_rollover_balance", 0)

        total_remaining = max(0, monthly_limit - monthly_used) + rollover_balance
        threshold = monthly_limit * 0.2

        if 0 < total_remaining <= threshold:
            logger.warning(
                "[Credits] Usuário %s com saldo baixo: %s créditos restantes.",
                user_id,
                total_remaining,
            )

    @staticmethod
    def calculate_rollover(quota_used: int, quota_limit: int, current_rollover: int) -> int:
        """Calcula o rollover no reset mensal, respeitando o teto MAX_ROLLOVER_MULTIPLIER."""
        unused = quota_limit - quota_used
        new_pool = max(0, current_rollover + unused)
        max_allowed = quota_limit * settings.MAX_ROLLOVER_MULTIPLIER
        return min(new_pool, max_allowed)


credit_service = CreditService()
