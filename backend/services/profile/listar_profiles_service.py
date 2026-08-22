from models.profile import Profile

class ListarProfilesService:
    @staticmethod
    def executar():
        return Profile.listar_todos()
