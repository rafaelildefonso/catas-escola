from openai import OpenAI
from core.config import settings
from typing import Dict, Any
import json

async def analyze_page_with_ai(url: str, html_content: str, user_context: str = "") -> Dict[str, Any]:
    """
    Analisa o conteúdo HTML da página usando OpenAI e retorna sugestões de automação.
    """
    
    # Limitar o tamanho do HTML para evitar custos excessivos
    max_html_length = 50000  # ~50k caracteres
    if len(html_content) > max_html_length:
        html_content = html_content[:max_html_length] + "... [conteúdo truncado]"
    
    prompt = f"""Você é um assistente de IA especializado em identificar tarefas automatizáveis em páginas web.

Analise o seguinte conteúdo HTML de uma página e identifique possíveis automações que podem ser executadas.

URL: {url}
Contexto do usuário: {user_context if user_context else "Nenhum contexto adicional fornecido"}

Conteúdo HTML (sanitizado):
{html_content}

Identifique tarefas que podem ser automatizadas, como:
1. Agendar eventos/reuniões (Google Calendar)
2. Salvar informações em Notion (segundo cérebro)
3. Enriquecer leads (LinkedIn, CRM)
4. Salvar bookmarks/artigos
5. Criar tarefas/to-dos

Para cada tarefa identificada, retorne um JSON com a seguinte estrutura:
{{
    "summary": "Resumo breve do conteúdo da página",
    "suggested_actions": [
        {{
            "type": "calendar|notion|lead|bookmark|task",
            "title": "Título da ação sugerida",
            "description": "Descrição detalhada do que será feito",
            "confidence": 0.0-1.0,
            "extracted_data": {{
                // Dados estruturados extraídos da página
            }}
        }}
    ]
}}

Retorne APENAS o JSON válido, sem markdown ou texto adicional."""

    try:
        client = OpenAI(api_key=settings.OPENAI_API_KEY)
        
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": "Você é um assistente especializado em análise de páginas web e identificação de automações. Sempre retorne JSON válido."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            temperature=0.3,
            max_tokens=2000
        )
        
        content = response.choices[0].message.content.strip()
        
        # Remover markdown code blocks se existirem
        if content.startswith("```json"):
            content = content[7:]
        if content.startswith("```"):
            content = content[3:]
        if content.endswith("```"):
            content = content[:-3]
        content = content.strip()
        
        # Parse JSON
        result = json.loads(content)
        
        # Garantir estrutura padrão
        if "suggested_actions" not in result:
            result["suggested_actions"] = []
        if "summary" not in result:
            result["summary"] = "Análise concluída"
        
        return result
        
    except json.JSONDecodeError:
        # Se falhar ao parsear JSON, retornar estrutura padrão
        return {
            "summary": "Erro ao processar resposta da IA",
            "suggested_actions": []
        }
    except Exception as e:
        raise Exception(f"Erro ao chamar OpenAI: {str(e)}")
