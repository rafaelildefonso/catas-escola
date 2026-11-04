from models.termo_aceite import TermoAceite, TIPOS_TERMO


class ConsultarAceiteTermosService:
    """Consulta o aceite atual do usuário para cada termo (LGPD)."""

    @staticmethod
    def executar(user_id):
        if not user_id:
            raise ValueError("Usuário é obrigatório")

        termos = {}
        aceito_todos = True
        for tipo in TIPOS_TERMO:
            aceite = TermoAceite.buscar_ultimo(user_id, tipo)
            if aceite is None:
                aceito_todos = False
            termos[tipo] = aceite.to_dict() if aceite else None

        return {
            "versao_atual": TermoAceite.VERSAO_ATUAL,
            "aceito_todos": aceito_todos,
            "termos": termos,
        }
