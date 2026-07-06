import json
from typing import List, Dict, Any
from .ai_providers.factory import AIFactory

class AIBase:
    """
    Base class for AI service calls, acting as a proxy to specific providers.
    Configurations are pulled from .env in the format: provider|model|api_url|api_key_env_var
    """

    @staticmethod
    async def call_ai(
        config_str: str, 
        system_prompt: str, 
        user_content: str, 
        history: List[Dict[str, Any]] = None,
        attachment_urls: List[str] = None,
        temperature: float = 0.1,
        response_mime_type: str = "application/json"
    ) -> Dict[str, Any]:
        """
        Faz a chamada à IA usando o design pattern Factory para escolher o provedor.
        """
        # Obter a instância concreta do Provider (Gemini ou Groq/OpenAI)
        provider = AIFactory.create(config_str)
        
        try:
            # Gerar a resposta bruta
            response = await provider.generate_response(
                system_prompt=system_prompt,
                user_content=user_content,
                history=history,
                attachment_urls=attachment_urls,
                temperature=temperature,
                response_mime_type=response_mime_type
            )
            
            raw_text = response["raw_text"]
            payload_response = response["payload_response"]
            
            # Extrair uso estritamente pelo provider
            usage_stats = provider.parse_usage(payload_response)

            # Preparar o dicionário de resultados e mesclar chaves protegidas
            result = {"_system_usage": usage_stats}

            # Validar JSON 
            if response_mime_type == "application/json":
                clean = raw_text.strip().replace("```json", "").replace("```", "").strip()
                try:
                    parsed_json = json.loads(clean)
                    result.update(parsed_json)
                except json.JSONDecodeError:
                    print(f"AIBase: Failed to parse JSON: {clean}")
                    # Retornará apenas {"_system_usage": ...} no caso de erro de parse, evitando quebras
            else:
                result["response_text"] = raw_text
                
            return result
            
        except Exception as e:
            print(f"AIBase: Error calling AI provider: {e}")
            raise
