import asyncio
from datetime import datetime, timezone, timedelta
from core.config import settings
from services.ai_base import AIBase
import re

class EntityExtractor:
    def __init__(self):
        pass

    def _parse_relative_date(self, date_str: str, current_date: datetime) -> str:
        """
        Converte datas relativas para ISO 8601 YYYY-MM-DD.
        """
        if not date_str:
            return None
            
        date_str = date_str.lower().strip()
        
        # Se já é data ISO, retorna
        if re.match(r'\d{4}-\d{2}-\d{2}', date_str):
            return date_str
            
        # Calcula datas relativas
        today = current_date.date()
        
        if date_str in ['hoje', 'today']:
            return today.isoformat()
        elif date_str in ['amanhã', 'amanha', 'tomorrow']:
            return (today + timedelta(days=1)).isoformat()
        elif date_str in ['depois de amanhã', 'depois de amanha', 'day after tomorrow']:
            return (today + timedelta(days=2)).isoformat()
        elif date_str in ['próxima semana', 'proxima semana', 'next week']:
            return (today + timedelta(weeks=1)).isoformat()
        elif date_str in ['semana que vem']:
            return (today + timedelta(weeks=1)).isoformat()
        elif date_str in ['próximo mês', 'proximo mes', 'next month']:
            # Ir para o primeiro dia do próximo mês
            if today.month == 12:
                return today.replace(year=today.year + 1, month=1, day=1).isoformat()
            else:
                return today.replace(month=today.month + 1, day=1).isoformat()
        
        # Tenta extrair "em X dias"
        match = re.search(r'em\s+(\d+)\s+dias?', date_str)
        if match:
            days = int(match.group(1))
            return (today + timedelta(days=days)).isoformat()
            
        # Tenta extrair dia da semana "próxima segunda"
        dias_semana = {
            'segunda': 0, 'terça': 1, 'terca': 1, 'quarta': 2,
            'quinta': 3, 'sexta': 4, 'sábado': 5, 'sabado': 5, 'domingo': 6
        }
        for dia, target_weekday in dias_semana.items():
            if dia in date_str:
                days_ahead = target_weekday - today.weekday()
                if days_ahead <= 0:  # Já passou essa semana, vai para próxima
                    days_ahead += 7
                return (today + timedelta(days=days_ahead)).isoformat()
        
        return date_str

    async def extract_entities(self, text: str, intent: str, history: list = []) -> dict:
        if intent == "conversation" or intent == "error":
            return {}

        current_time = datetime.now(timezone.utc)
        current_time_iso = current_time.isoformat()
        current_date = current_time.date().isoformat()
        current_time_only = current_time.strftime("%H:%M")
        current_weekday = ['segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo'][current_time.weekday()]
        
        system_prompt = f"""You are an intelligent entity extractor for CATAS.
Your goal is to extract specific information from the user's message based on their detected intent.

CURRENT CONTEXT (use this to interpret relative dates):
- Today is: {current_date} ({current_weekday})
- Current time: {current_time_only}
- Current date/time ISO: {current_time_iso}
Detected Intent: {intent}

INSTRUCTIONS:
- Extract ALL mentioned information
- For dates: Return RELATIVE terms ("amanhã", "próxima segunda") - the system will convert
- For times: Use HH:MM format (24-hour)
- For missing fields: Use null (not empty string)
- Be precise and extract what the user ACTUALLY said

"""
        
        if intent == "calendar_create_event":
            system_prompt += """Extract calendar event details from the user's message.

REQUIRED FIELDS (extract if present):
- date: Relative date term (e.g., "amanhã", "hoje", "próxima terça", "em 3 dias") OR null
- time: Time in HH:MM format (e.g., "09:00", "14:30") OR null  
- title: Event title/name (e.g., "Reunião de Vendas", "Almoço com cliente") OR null
- description: Additional details OR null
- attendees: List of participant names/emails OR empty list []

EXAMPLES:
User: "Reunião amanhã às 9h com João"
→ {"date": "amanhã", "time": "09:00", "title": "Reunião", "description": null, "attendees": ["João"]}

User: "Agendar almoço com Maria na sexta às 12:30"
→ {"date": "sexta", "time": "12:30", "title": "Almoço com Maria", "description": null, "attendees": ["Maria"]}

User: "Lembrar de comprar presente dia 25"
→ {"date": "2026-04-25", "time": null, "title": "Comprar presente", "description": null, "attendees": []}

Return ONLY JSON: {"date": "...", "time": "...", "title": "...", "description": "...", "attendees": []}
"""
        elif intent == "task_create":
            system_prompt += """
            Extract the following fields. If a field is not mentioned, return null.
            - task_name: The title or description of the task to be done.
            - due_date: Standardize to ISO 8601 or understandable date string.
            - priority: One of ["alta", "media", "baixa"]. Infer from context.
            - value: Any monetary or numerical value inherently tied to the task (e.g., "5 reais" -> "5").
            
            Return JSON format: {"task_name": "...", "due_date": "...", "priority": "...", "value": "..."}
            """
        elif intent == "email_draft":
            system_prompt += """
            Extract the following fields. If a field is not mentioned, return null.
            - subject: Subject line of the email.
            - recipient: The name or email address of the person receiving the email.
            - body_topic: A short summary of what the email should say.
            
            Return JSON format: {"subject": "...", "recipient": "...", "body_topic": "..."}
            """

        for attempt in range(3):
            try:
                # Entities usually only need current context, but AIBase can handle it
                # Converte o histórico para o formato esperado pelo AIBase
                formatted_history = []
                if history:
                    for msg in history:
                        role = "user" if msg.get("role") == "user" or msg.get("isUser") else "assistant"
                        content = msg.get("content") or msg.get("text") or ""
                        formatted_history.append({"role": role, "content": content})

                result = await AIBase.call_ai(
                    config_str=settings.AGENT_ENTITY_EXTRACTOR,
                    system_prompt=system_prompt,
                    user_content=text,
                    history=formatted_history
                )
                
                # Post-processamento: converter datas relativas para absolutas
                if intent == "calendar_create_event" and result:
                    raw_date = result.get("date")
                    if raw_date:
                        parsed_date = self._parse_relative_date(raw_date, current_time)
                        if parsed_date:
                            result["date"] = parsed_date
                            print(f"📅 [EntityExtractor] Date '{raw_date}' parsed to '{parsed_date}'")
                    
                    # Garantir que attendees seja uma lista
                    if result.get("attendees") is None:
                        result["attendees"] = []
                    
                    # Log do resultado final
                    print(f"📋 [EntityExtractor] Calendar entities: {result}")
                
                return result
                
            except Exception as e:
                print(f"Error extracting entities (attempt {attempt+1}): {e}")
                if attempt < 2:
                    await asyncio.sleep(1)
                    
        return {} # Empty entities on failure
