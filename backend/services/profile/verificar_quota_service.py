from datetime import date, datetime, timezone

from models.profile import Profile


CONFIG_QUOTA = {
    "basic": {"limit": 500, "models": ["CATAS Basic"], "attachment_limit": 5},
    "pro": {"limit": 7500, "models": ["CATAS Basic", "CATAS Pro"], "attachment_limit": 100},
    "max": {"limit": 25000, "models": ["CATAS Basic", "CATAS Pro", "CATAS MAX"], "attachment_limit": 1000},
}

class VerificarQuotaService:
    """Verifica saldo mensal + rollover do usuário para usar a IA.

    Reinicia a cota quando o mês muda (transferindo sobra para rollover).
    Não debita crédito: o débito acontece no pipeline de IA.
    """

    @staticmethod
    def executar(user_id: str, model_requested: str = None):
        perfil = VerificarQuotaService._obter_perfil(user_id)

        tier = (perfil.get("subscription_tier") or "basic").lower()
        config = CONFIG_QUOTA.get(tier, CONFIG_QUOTA["basic"])

        if model_requested and model_requested not in config["models"]:
            return False, f"O modelo {model_requested} não está disponível no seu plano {tier.capitalize()}.", perfil

        if VerificarQuotaService._deve_reiniciar(perfil):
            VerificarQuotaService._reiniciar_quota(user_id, perfil, config)

        limite = perfil.get("monthly_quota_limit") or config["limit"]
        usado = perfil.get("quota_used", 0) or 0
        rollover = perfil.get("rollover_credits", 0) or 0

        if (limite - usado) + rollover <= 0:
            return False, f"Seu saldo de {limite} créditos acabou. Faça upgrade ou aguarde o próximo ciclo.", perfil

        return True, "", perfil

    @staticmethod
    def _obter_perfil(user_id: str) -> dict:
        model = Profile.buscar_por_id(user_id)
        if not model:
            model = VerificarQuotaService._criar_perfil_padrao(user_id)
        return model.to_dict()

    @staticmethod
    def _criar_perfil_padrao(user_id: str):
        perfil = Profile(
            id=user_id,
            subscription_tier="basic",
            quota_used=0,
            last_quota_reset=datetime.now(timezone.utc),
        )
        perfil.salvar()
        return perfil

    @staticmethod
    def _deve_reiniciar(perfil: dict) -> bool:
        ultimo_reset = perfil.get("last_quota_reset")
        hoje = date.today()
        if not ultimo_reset:
            return True
        try:
            data_reset = ultimo_reset
            if isinstance(data_reset, str):
                data_reset = datetime.fromisoformat(data_reset.replace("Z", "+00:00"))
            return data_reset.month != hoje.month or data_reset.year != hoje.year
        except (ValueError, TypeError):
            return True

    @staticmethod
    def _reiniciar_quota(user_id: str, perfil: dict, config: dict):
        from services.profile.credit_service import credit_service

        usado = perfil.get("quota_used", 0) or 0
        limite = perfil.get("monthly_quota_limit") or config["limit"]
        rollover_atual = perfil.get("rollover_credits", 0) or 0

        novo_rollover = credit_service.calculate_rollover(usado, limite, rollover_atual)

        model = Profile.buscar_por_id(user_id)
        if model:
            model.atualizar(
                quota_used=0,
                rollover_credits=novo_rollover,
                last_quota_reset=datetime.now(timezone.utc),
            )

        perfil["quota_used"] = 0
        perfil["rollover_credits"] = novo_rollover
