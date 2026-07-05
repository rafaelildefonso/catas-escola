from app.models.ai_suggestion import AiSuggestion

class DeletarAiSuggestionService:
    @staticmethod
    def executar(id):
        model = AiSuggestion.buscar_por_id(id)
        if not model:
            raise ValueError(f"AiSuggestion com id {id} nao encontrado")
        model.deletar()
        return None
