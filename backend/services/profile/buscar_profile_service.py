from models.profile import Profile

class BuscarProfileService:
    @staticmethod
    def executar(id):
        model = Profile.buscar_por_id(id)
        if not model:
            raise ValueError(f"Profile com id {id} nao encontrado")
        return model
