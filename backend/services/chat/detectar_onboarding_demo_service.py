import re
from datetime import datetime, timedelta
from typing import Optional


MAPA_DIAS_SEMANA = {
    "segunda": 0, "segunda-feira": 0, "2": 0,
    "terça": 1, "terça-feira": 1, "3": 1,
    "quarta": 2, "quarta-feira": 2, "4": 2,
    "quinta": 3, "quinta-feira": 3, "5": 3,
    "sexta": 4, "sexta-feira": 4, "6": 4,
    "sábado": 5, "sabado": 5,
    "domingo": 6, "7": 6,
}


class DetectarOnboardingDemoService:
    """Detecta mensagens de demonstração de onboarding ("fechamos contrato com X...").

    Retorna dict com client_name/meeting_date/meeting_time ou None.
    """

    PADROES = [
        r"(?:fechamos\s+contrato|contrato\s+fechado|contrato\s+com|novo\s+cliente|onboarding)\s*(?:com|do|da|para|de)?\s*[:\-]?\s*([A-Za-zÀ-ÿ\s]+?)(?:\s*[.,;!?]|\s+e\s+|\s+para\s+|\s+organize\s+|\s+agende\s+|\s*$)",
        r"(?:contrato|cliente)\s+(?:com|do|da|para|de)\s+([A-Za-zÀ-ÿ\s]+?)(?:\s*[.,;!?]|\s+para\s+|\s+organize\s+|\s+agende\s+|\s*$)",
    ]

    @staticmethod
    def executar(message: str) -> Optional[dict]:
        text = (message or "").lower().strip()

        nome_cliente = DetectarOnboardingDemoService._extrair_nome(text)
        if not nome_cliente:
            return None

        horario = DetectarOnboardingDemoService._extrair_horario(text)
        data = DetectarOnboardingDemoService._extrair_data(text)

        return {
            "client_name": nome_cliente,
            "meeting_date": data,
            "meeting_time": horario,
        }

    @staticmethod
    def _extrair_nome(text: str) -> Optional[str]:
        for pattern in DetectarOnboardingDemoService.PADROES:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                candidate = match.group(1).strip().title()
                if len(candidate) > 1:
                    return candidate
        return None

    @staticmethod
    def _extrair_horario(text: str) -> str:
        time_match = re.search(r'(\d{1,2})[:h](\d{2})?\s*(?:h|hrs|horas)?', text)
        if time_match:
            h, m = time_match.group(1), time_match.group(2) or "00"
            return f"{h.zfill(2)}:{m}"
        return "14:00"

    @staticmethod
    def _extrair_data(text: str) -> str:
        date_match = re.search(
            r'(sexta|segunda|terça|quarta|quinta|sábado|domingo|hoje|amanhã|depois de amanhã|depois de amanha|sabado)',
            text,
            re.IGNORECASE,
        )
        if date_match:
            return DetectarOnboardingDemoService._resolver_data(date_match.group(1))
        return (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")

    @staticmethod
    def _resolver_data(day_ref: str) -> str:
        hoje = datetime.now()
        ref = day_ref.lower().strip()

        if ref == "hoje":
            return hoje.strftime("%Y-%m-%d")
        if ref in ("amanhã", "amanha"):
            return (hoje + timedelta(days=1)).strftime("%Y-%m-%d")
        if ref in ("depois de amanhã", "depois de amanha"):
            return (hoje + timedelta(days=2)).strftime("%Y-%m-%d")

        alvo = MAPA_DIAS_SEMANA.get(ref)
        if alvo is not None:
            dias = alvo - hoje.weekday()
            if dias <= 0:
                dias += 7
            return (hoje + timedelta(days=dias)).strftime("%Y-%m-%d")

        return (hoje + timedelta(days=1)).strftime("%Y-%m-%d")
