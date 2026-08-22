from models.ai_suggestion import AiSuggestion

class AtualizarAiSuggestionService:
    @staticmethod
    def executar(id, dados):
        if not dados:
            raise ValueError("Dados sao obrigatorios")
        model = AiSuggestion.buscar_por_id(id)
        if not model:
            raise ValueError(f"AiSuggestion com id {id} nao encontrado")
        model.atualizar(**dados)
        return model
