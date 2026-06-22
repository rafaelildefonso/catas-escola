import httpx
from typing import List, Dict, Any, Optional
from .base import AIProvider

class GroqProvider(AIProvider):
    """
    Provider para Groq e qualquer API compatível com o padrão OpenAI.
    """
    async def generate_response(
        self,
        system_prompt: str,
        user_content: str,
        history: Optional[List[Dict[str, Any]]] = None,
        attachment_urls: Optional[List[str]] = None,
        temperature: float = 0.1,
        response_mime_type: str = "application/json"
    ) -> Dict[str, Any]:
        
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
            
        if history:
            # We assume history is passed in {"role": ..., "content": ...} format
            messages.extend(history)
        
        # Attachment support is currently rudimentary for standard REST non-vision models
        user_text = user_content
        if attachment_urls:
            user_text += f"\n\n[Attachments: {', '.join(attachment_urls)}]"
            
        messages.append({"role": "user", "content": user_text})

        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature
        }
        
        if response_mime_type == "application/json":
            payload["response_format"] = {"type": "json_object"}

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(self.api_url, json=payload, headers=headers)
            
            if response.status_code != 200:
                print(f"❌ GroqProvider Error ({response.status_code}): {response.text}")
                response.raise_for_status()
                
            data = response.json()
            
            raw_text = data["choices"][0]["message"]["content"]
            
            return {
                "raw_text": raw_text,
                "payload_response": data
            }

    def parse_usage(self, response_data: dict) -> dict:
        usage = response_data.get("usage", {})
        
        return {
            "prompt_tokens": usage.get("prompt_tokens", 0),
            "completion_tokens": usage.get("completion_tokens", 0),
            "total_tokens": usage.get("total_tokens", 0)
        }
