from models.page_analysis_cache import PageAnalysisCache

class CriarPageAnalysisCacheService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = PageAnalysisCache(**dados)
        model.salvar()
        return model
