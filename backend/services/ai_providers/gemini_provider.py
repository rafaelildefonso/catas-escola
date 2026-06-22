import httpx
import base64
from typing import List, Dict, Any, Optional
from .base import AIProvider

class GeminiProvider(AIProvider):
    async def generate_response(
        self,
        system_prompt: str,
        user_content: str,
        history: Optional[List[Dict[str, Any]]] = None,
        attachment_urls: Optional[List[str]] = None,
        temperature: float = 0.1,
        response_mime_type: str = "application/json"
    ) -> Dict[str, Any]:
        
        content_parts = []
        
        if attachment_urls:
            async with httpx.AsyncClient(timeout=10.0) as client:
                for url in attachment_urls:
                    try:
                        ext = url.split('.')[-1].split('?')[0].lower()
                        if ext in ['jpg', 'jpeg', 'png', 'webp', 'gif']:
                            response = await client.get(url)
                            if response.status_code == 200:
                                mime_type = f"image/{ext}" if ext != 'jpg' else "image/jpeg"
                                content_parts.append({
                                    "inline_data": {
                                        "mime_type": mime_type,
                                        "data": base64.b64encode(response.content).decode('utf-8')
                                    }
                                })
                    except Exception as e:
                        print(f"⚠️ GeminiProvider: Error downloading attachment: {e}")

        content_parts.append({"text": user_content})

        payload = {
            "contents": [
                {
                    "role": "user",
                    "parts": content_parts
                }
            ],
            "generationConfig": {
                "temperature": temperature,
                "responseMimeType": response_mime_type
            }
        }
        
        if system_prompt:
            payload["system_instruction"] = {
                "parts": [{"text": system_prompt}]
            }
        
        if history:
            gemini_history = []
            for msg in history:
                gemini_history.append({
                    "role": "user" if msg.get("role") == "user" or msg.get("isUser") else "model",
                    "parts": [{"text": msg.get("content", "")}]
                })
            # Insert history before the current message
            payload["contents"] = gemini_history + payload["contents"]

        url = f"{self.api_url.rstrip('/')}/models/{self.model}:generateContent?key={self.api_key}" if "generateContent" not in self.api_url else f"{self.api_url}?key={self.api_key}"
        headers = {"Content-Type": "application/json"}
        
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(url, json=payload, headers=headers)
            
            if response.status_code != 200:
                print(f"❌ GeminiProvider Error ({response.status_code}): {response.text}")
                response.raise_for_status()
                
            data = response.json()
            
            # Extract raw string
            raw_text = data["candidates"][0]["content"]["parts"][0]["text"]
            
            return {
                "raw_text": raw_text,
                "payload_response": data
            }

    def parse_usage(self, response_data: dict) -> dict:
        usage = response_data.get("usageMetadata", {})
        
        return {
            "prompt_tokens": usage.get("promptTokenCount", 0),
            "completion_tokens": usage.get("candidatesTokenCount", 0),
            "total_tokens": usage.get("totalTokenCount", 0)
        }
