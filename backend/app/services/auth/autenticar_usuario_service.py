from app.models.user import User
from app.models.profile import Profile


class AutenticacaoError(ValueError):
    def __init__(self, message, status_code=401):
        super().__init__(message)
        self.status_code = status_code


class AutenticarUsuarioService:
    @staticmethod
    def executar(dados):
        email = (dados.get("email") or "").strip().lower()
        password = dados.get("password") or ""
        if not email or not password:
            raise AutenticacaoError("Email e senha sao obrigatorios", status_code=400)
        user = User.buscar_por_email(email)
        if not user or not user.check_password(password):
            raise AutenticacaoError("Email ou senha invalidos", status_code=401)
        profile = Profile.buscar_por_id(user.id)
        if not profile:
            profile = Profile(id=user.id, subscription_tier="basic")
            profile.salvar()
        token = user.generate_token()
        return {"token": token, "user": user, "profile": profile}