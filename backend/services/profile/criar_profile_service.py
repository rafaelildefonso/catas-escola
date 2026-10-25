from models.profile import Profile


class CriarProfileService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        cols = {c.key for c in Profile.__table__.columns}
        campos_protegidos = {
            "subscription_tier",
            "monthly_quota_limit",
            "quota_used",
            "rollover_credits",
            "stripe_customer_id",
            "stripe_subscription_id",
            "subscription_status",
            "stripe_current_period_end",
        }
        filtrados = {k: v for k, v in dados.items() if k in cols and k not in campos_protegidos}
        model = Profile(**filtrados)
        model.salvar()
        return model
