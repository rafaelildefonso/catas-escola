from app.models.user import User


class DeletarUserService:
    @staticmethod
    def executar(id):
        user = User.buscar_por_id(id)
        if not user:
            raise ValueError(f"User com id {id} nao encontrado")
        user.deletar()
        return None
