from models.profile import Profile

class DeletarProfileService:
    @staticmethod
    def executar(id):
        model = Profile.buscar_por_id(id)
        if not model:
            raise ValueError(f"Profile com id {id} nao encontrado")
        model.deletar()
        return None
