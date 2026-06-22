import os
from .base import AIProvider
from .gemini_provider import GeminiProvider
from .groq_provider import GroqProvider

class AIFactory:
    """
    Fábrica responsável por criar a instância correta do provedor de IA 
    com base na string de configuração (provider|model|api_url|api_key_env_var).
    """

    @staticmethod
    def create(config_str: str) -> AIProvider:
        parts = config_str.split('|')
        provider_name = parts[0] if len(parts) > 0 else 'groq'
        model = parts[1] if len(parts) > 1 else 'llama-3.1-8b-instant'
        api_url = parts[2] if len(parts) > 2 else 'https://api.groq.com/openai/v1/chat/completions'
        api_key_name = parts[3] if len(parts) > 3 else 'GROQ_API_KEY'
        
        api_key = os.getenv(api_key_name, "")

        if provider_name.lower() == 'gemini':
            return GeminiProvider(api_url=api_url, api_key=api_key, model=model)
        else:
            return GroqProvider(api_url=api_url, api_key=api_key, model=model)
