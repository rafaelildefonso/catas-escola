from models.integration import Integration

class AtualizarIntegrationService:
    @staticmethod
    def executar(id, dados, user_id):
        model = Integration.query.filter_by(id=id, user_id=user_id).first()
        if not model:
            raise ValueError(f"Integration com id {id} nao encontrado")
        if not isinstance(dados, dict) or set(dados) != {"settings"} or not isinstance(dados["settings"], dict):
            raise ValueError("Dados de integracao nao permitidos")
        model.atualizar(**dados)
        return model
