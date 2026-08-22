from models.profile import Profile


class CriarProfileService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        cols = {c.key for c in Profile.__table__.columns}
        filtrados = {k: v for k, v in dados.items() if k in cols}
        model = Profile(**filtrados)
        model.salvar()
        return model
