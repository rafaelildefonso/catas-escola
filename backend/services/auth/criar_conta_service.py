from datetime import datetime, timezone

from models.profile import Profile
from models.termo_aceite import TermoAceite
from services.user.criar_user_service import CriarUserService
from services.termo.registrar_aceite_service import RegistrarAceiteTermosService


class CriarContaService:
    @staticmethod
    def executar(dados):
        # Conformidade LGPD: a conta só é criada com aceite explícito dos Termos de
        # Uso e do Termo de Consentimento, registrado com versão e timestamp.
        if dados.get("aceito_termos") is not True:
            raise ValueError(
                "É necessário aceitar o Termo de Uso e o Termo de Consentimento."
            )

        user = CriarUserService.executar(dados)
        profile = Profile(
            id=user.id,
            subscription_tier="basic",
            quota_used=0,
            last_quota_reset=datetime.now(timezone.utc),
        )
        profile.salvar()

        # Persiste a comprovação do aceite para a nova conta
        RegistrarAceiteTermosService.executar(
            user.id,
            {"origem": "signup", "versao": TermoAceite.VERSAO_ATUAL},
        )

        token = user.generate_token()
        return {"token": token, "user": user, "profile": profile}