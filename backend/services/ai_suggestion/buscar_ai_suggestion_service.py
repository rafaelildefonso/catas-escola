from models.ai_suggestion import AiSuggestion

class BuscarAiSuggestionService:
    @staticmethod
    def executar(id):
        model = AiSuggestion.buscar_por_id(id)
        if not model:
            raise ValueError(f"AiSuggestion com id {id} nao encontrado")
        return model
