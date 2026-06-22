from typing import List, Dict, Any, Optional
from abc import ABC, abstractmethod


class AIProvider(ABC):
    """
    Classe base para provedores de Inteligência Artificial.
    Define o contrato padrão para envio de requests e parsing de métricas de uso (tokens).
    """

    def __init__(self, api_url: str, api_key: str, model: str):
        self.api_url = api_url
        self.api_key = api_key
        self.model = model

    @abstractmethod
    async def generate_response(
        self,
        system_prompt: str,
        user_content: str,
        history: Optional[List[Dict[str, Any]]] = None,
        attachment_urls: Optional[List[str]] = None,
        temperature: float = 0.1,
        response_mime_type: str = "application/json"
    ) -> Dict[str, Any]:
        """
        Executa a chamada na API do provedor e retorna a string bruta da resposta 
        mais o bloco original retornado pela plataforma.
        """
        pass

    @abstractmethod
    def parse_usage(self, response_data: dict) -> dict:
        """
        Extrai o consumo de tokens da resposta bruta da API de maneira padronizada.
        Garante que sempre teremos "prompt_tokens", "completion_tokens" e "total_tokens".
        """
        pass
