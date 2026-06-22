import re
from core.config import settings


def sanitize_error(e: Exception, friendly_msg: str = "Erro interno do servidor") -> str:
    if settings.ENVIRONMENT == "development":
        msg = str(e)
        msg = re.sub(r'\?key=[^&\s]+', '?key=***', msg)
        msg = re.sub(r'key=[^&\s]+', 'key=***', msg)
        return msg
    return friendly_msg
