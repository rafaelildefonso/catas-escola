from app.models.user import User
from app.models.profile import Profile


class ObterContaService:
    @staticmethod
    def executar(user_id):
        user = User.buscar_por_id(user_id)
        if not user:
            raise ValueError("Usuario nao encontrado")
        profile = Profile.buscar_por_id(user.id)
        if not profile:
            profile = Profile(id=user.id, subscription_tier="basic")
            profile.salvar()
        return {"user": user, "profile": profile}