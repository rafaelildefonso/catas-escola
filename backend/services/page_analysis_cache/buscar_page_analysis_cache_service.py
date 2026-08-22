from models.page_analysis_cache import PageAnalysisCache

class BuscarPageAnalysisCacheService:
    @staticmethod
    def executar(id):
        model = PageAnalysisCache.buscar_por_id(id)
        if not model:
            raise ValueError(f"PageAnalysisCache com id {id} nao encontrado")
        return model
