from app.models.profile import Profile

class AtualizarProfileService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = Profile.buscar_por_id(id)
        if not model:
            raise ValueError(f"Profile com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
