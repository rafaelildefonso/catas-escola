from models.termo_aceite import TermoAceite, TIPOS_TERMO


class RegistrarAceiteTermosService:
    """Registra o aceite de um ou mais termos (LGPD), evitando duplicidade
    para a mesma versão."""

    @staticmethod
    def executar(user_id, dados=None):
        dados = dados or {}
        tipos = dados.get("tipos") or list(TIPOS_TERMO)
        versao = dados.get("versao") or TermoAceite.VERSAO_ATUAL
        origem = dados.get("origem") or "web"

        if not user_id:
            raise ValueError("Usuário é obrigatório")

        if not isinstance(tipos, (list, tuple)) or not tipos:
            raise ValueError("Informe pelo menos um tipo de termo")

        for tipo in tipos:
            if tipo not in TIPOS_TERMO:
                raise ValueError(
                    f"Tipo de termo inválido: {tipo}. Use {' ou '.join(TIPOS_TERMO)}."
                )

        registrados = []
        for tipo in tipos:
            if TermoAceite.existe_aceite(user_id, tipo, versao):
                registrados.append(TermoAceite.buscar_ultimo(user_id, tipo))
                continue
            aceite = TermoAceite(
                user_id=user_id,
                tipo=tipo,
                versao=versao,
                origem=origem,
            )
            aceite.salvar()
            registrados.append(aceite)

        return {
            "aceito_todos": True,
            "versao": versao,
            "termos": [aceite.to_dict() for aceite in registrados],
        }
