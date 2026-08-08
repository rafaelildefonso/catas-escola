from app.repositories.dashboard_repository import estatisticas_dashboard


class GerarEstatisticasDashboardService:
    """Caso de uso: estatísticas agregadas do dashboard."""

    @staticmethod
    def executar(user_id: str, dias=None) -> dict:
        if not user_id:
            raise ValueError("user_id e obrigatorio")

        try:
            dias_int = max(1, min(int(dias), 365))
        except (TypeError, ValueError):
            dias_int = 7

        return estatisticas_dashboard(user_id, dias_int)