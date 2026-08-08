from app.repositories.chat_repository import buscar_mensagens


class BuscarMensagensService:
    """Caso de uso: busca textual em mensagens do usuário."""

    @staticmethod
    def executar(user_id: str, termo: str, limite=50, deslocamento=0) -> dict:
        if not user_id:
            raise ValueError("user_id e obrigatorio")
        if not termo or not termo.strip():
            return {"items": [], "total": 0}
        if len(termo.strip()) < 2:
            raise ValueError("termo deve ter pelo menos 2 caracteres")

        return buscar_mensagens(
            user_id=user_id,
            termo=termo.strip(),
            limite=_limitar(limite, 1, 100, 50),
            deslocamento=_limitar(deslocamento, 0, None, 0),
        )


def _limitar(valor, minimo, maximo, padrao):
    try:
        inteiro = int(valor)
    except (TypeError, ValueError):
        return padrao
    inteiro = max(inteiro, minimo)
    if maximo is not None:
        inteiro = min(inteiro, maximo)
    return inteiro