from models.ai_suggestion import AiSuggestion

class CriarAiSuggestionService:
    @staticmethod
    def executar(dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = AiSuggestion(**dados)
        model.salvar()
        return model
