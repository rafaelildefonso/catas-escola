from models.integration import Integration


def listar_integracoes_do_usuario(user_id: str) -> list:
    """Integrações do usuário sem expor tokens (filtro por posse)."""
    rows = (
        Integration.query
        .filter(Integration.user_id == user_id)
        .all()
    )
    dados = [r.to_dict() for r in rows]
    for item in dados:
        item.pop("access_token", None)
        item.pop("refresh_token", None)
    return dados
