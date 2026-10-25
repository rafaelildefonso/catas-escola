from models.integration import Integration

class CriarIntegrationService:
    @staticmethod
    def executar(dados, user_id):
        if not isinstance(dados, dict) or not dados.get("provider"):
            raise ValueError("Dados e provider sao obrigatorios")
        if set(dados) - {"provider", "settings"}:
            raise ValueError("Dados de integracao nao permitidos")
        if not isinstance(dados["provider"], str) or not dados["provider"].strip():
            raise ValueError("Provider invalido")
        if dados.get("settings") is not None and not isinstance(dados["settings"], dict):
            raise ValueError("Settings invalidos")
        if Integration.query.filter_by(user_id=user_id, provider=dados["provider"]).first():
            raise ValueError("Integracao ja existe")
        model = Integration(user_id=user_id, provider=dados["provider"], settings=dados.get("settings") or {})
        model.salvar()
        return model
