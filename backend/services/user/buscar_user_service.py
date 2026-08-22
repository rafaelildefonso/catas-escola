from models.user import User


class BuscarUserService:
    @staticmethod
    def executar(id):
        user = User.buscar_por_id(id)
        if not user:
            raise ValueError(f"User com id {id} nao encontrado")
        return user
