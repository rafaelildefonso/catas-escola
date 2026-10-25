from models.profile import Profile

_CAMPOS_GERENCIADOS_PELO_BILLING = {
    "subscription_tier",
    "monthly_quota_limit",
    "quota_used",
    "rollover_credits",
    "stripe_customer_id",
    "stripe_subscription_id",
    "subscription_status",
    "stripe_current_period_end",
}


class ProfileFieldProtectedError(ValueError):
    pass


class AtualizarProfileService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        campos_protegidos = _CAMPOS_GERENCIADOS_PELO_BILLING.intersection(dados)
        if campos_protegidos:
            raise ProfileFieldProtectedError(
                "Dados de plano e créditos só podem ser alterados pelo sistema de cobrança"
            )
        model = Profile.buscar_por_id(id)
        if not model:
            raise ValueError(f"Profile com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
