from repositories.base import executar_linha


def listar_integracoes_do_usuario(user_id: str) -> list:
    """Integracoes do usuario sem expor tokens (filtro por posse)."""
    rows = executar_linha(
        """SELECT id, user_id, provider, is_connected, settings, created_at, updated_at
           FROM integrations
           WHERE user_id = :user_id""",
        user_id=user_id,
    )
    return rows
