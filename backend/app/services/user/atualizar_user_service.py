from app.models.user import User


class AtualizarUserService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        user = User.buscar_por_id(id)
        if not user:
            raise ValueError(f"User com id {id} nao encontrado")
        dados = dict(dados)
        password = dados.pop("password", None)
        if password:
            user.set_password(password)
        user.atualizar(**dados)
        return user
