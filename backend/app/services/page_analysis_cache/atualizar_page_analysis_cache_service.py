from app.models.page_analysis_cache import PageAnalysisCache

class AtualizarPageAnalysisCacheService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = PageAnalysisCache.buscar_por_id(id)
        if not model:
            raise ValueError(f"PageAnalysisCache com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
