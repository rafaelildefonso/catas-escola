from models.user import User


class EmailJaCadastradoError(ValueError):
    pass


class CriarUserService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        email = (dados.get("email") or "").strip().lower()
        password = dados.get("password") or ""
        if not email or not password:
            raise ValueError("Email e senha sao obrigatorios")
        if "@" not in email:
            raise ValueError("Email invalido")
        if len(password) < 8:
            raise ValueError("Senha deve ter no minimo 8 caracteres")
        if User.buscar_por_email(email):
            raise EmailJaCadastradoError("Email ja cadastrado")
        user = User(email=email)
        user.set_password(password)
        user.salvar()
        return user
