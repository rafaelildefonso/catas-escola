from datetime import datetime, timezone

from models.profile import Profile
from services.user.criar_user_service import CriarUserService


class CriarContaService:
    @staticmethod
    def executar(dados):
        user = CriarUserService.executar(dados)
        profile = Profile(
            id=user.id,
            subscription_tier="basic",
            quota_used=0,
            last_quota_reset=datetime.now(timezone.utc),
        )
        profile.salvar()
        token = user.generate_token()
        return {"token": token, "user": user, "profile": profile}