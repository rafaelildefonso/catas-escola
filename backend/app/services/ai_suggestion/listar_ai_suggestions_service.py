from app.models.ai_suggestion import AiSuggestion

class ListarAiSuggestionsService:
    @staticmethod
    def executar():
        return AiSuggestion.listar_todos()
