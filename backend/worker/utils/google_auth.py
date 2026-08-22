"""
Utilitário de resolução de credenciais OAuth para os módulos do Worker.
Centraliza a busca do access_token com refresh automático via integrations.py.
"""
import logging

logger = logging.getLogger(__name__)


def get_google_access_token(user_id: str, provider: str = "google_gmail") -> str:
    """
    Retorna o access_token válido (com refresh automático se necessário)
    para a integração Google do usuário.

    Lança ValueError com mensagem clara se a integração não existir,
    para que o runner possa comunicar ao usuário de forma amigável.
    """
    if not user_id:
        raise ValueError(
            "user_id não fornecido ao módulo. "
            "Certifique-se de que o plano passa o user_id no trigger."
        )

    from worker.repositorio_dados import obter_integracao

    integration = obter_integracao(user_id, provider)
    if not integration:
        raise ValueError(
            f"Integração '{provider}' não encontrada para o usuário. "
            f"Peça ao usuário para conectar a conta em Configurações > Integrações."
        )

    access_token = integration.get("access_token")
    if not access_token:
        raise ValueError(
            f"Token de acesso inválido ou expirado para a integração '{provider}'. "
            f"Peça ao usuário para reconectar a conta."
        )

    logger.debug(f"🔑 Token OAuth resolvido para user={user_id}, provider={provider}")
    return access_token
