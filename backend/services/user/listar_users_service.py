from models.user import User


class ListarUsersService:
    @staticmethod
    def executar():
        return User.listar_todos()
