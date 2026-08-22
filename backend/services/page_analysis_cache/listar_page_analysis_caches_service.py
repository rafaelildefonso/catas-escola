from models.page_analysis_cache import PageAnalysisCache

class ListarPageAnalysisCachesService:
    @staticmethod
    def executar():
        return PageAnalysisCache.listar_todos()
