from datetime import datetime, timedelta

class PayloadBuilder:
    def _add_step_ids(self, steps: list) -> list:
        for i, step in enumerate(steps):
            if "step_id" not in step:
                step["step_id"] = f"step_{i + 1}"
        return steps

    def build_payload(self, intent: str, entities: dict) -> dict:
        """
        Takes the extracted intent and entities and formats them as action_details expected by the AutomationWorkflow.
        """
        steps = []
        name = "Ação CATAS"
        
        if intent == "email_draft":
            name = "Enviar E-mail"
            steps.append({
                "module_id": "gmail.send_email",
                "params": {
                    "to": entities.get("recipient"),
                    "subject": entities.get("subject", "Sem Assunto"),
                    "body": entities.get("body_topic") or ""
                }
            })
            
        elif intent == "calendar_create_event":
            name = "Agendar Evento"
            
            # Preparar data/hora
            date_str = entities.get("date")
            time_str = entities.get("time", "09:00")
            
            if date_str:
                start_dt_str = f"{date_str}T{time_str}:00"
                # Calcular end_dt (padrão 1 hora depois)
                try:
                    start_dt = datetime.fromisoformat(start_dt_str.replace('Z', '+00:00'))
                    end_dt = start_dt + timedelta(hours=1)
                    end_dt_str = end_dt.isoformat()
                except (ValueError, TypeError):
                    end_dt_str = start_dt_str
            else:
                start_dt_str = None
                end_dt_str = None

            steps.append({
                "module_id": "google_calendar.create_event",
                "params": {
                    "summary": entities.get("title", "Novo Evento"),
                    "start": start_dt_str,
                    "end": end_dt_str,
                    "description": entities.get("description", ""),
                    "attendees": entities.get("attendees", [])
                }
            })
            # Se houver informações de e‑mail (destinatário, assunto ou corpo), adiciona passo de envio
            email_recipient = entities.get("recipient") or entities.get("to")
            email_subject = entities.get("subject")
            email_body = entities.get("body_topic") or entities.get("body")
            if email_recipient or email_subject or email_body:
                steps.append({
                    "module_id": "gmail.send_email",
                    "params": {
                        "to": email_recipient,
                        "subject": email_subject or "Sem Assunto",
                        "body": email_body or ""
                    }
                })
            
        elif intent == "task_create":
            name = "Criar Tarefa"
            steps.append({
                "module_id": "google_sheets.append_row",
                "params": {
                    "spreadsheet_id": "primary",
                    "range": "Tarefas!A:D",
                    "values": [[
                        entities.get("task_name"),
                        entities.get("due_date"),
                        entities.get("priority"),
                        entities.get("value")
                    ]]
                }
            })

        elif intent == "spreadsheet_create":
            title = (entities.get("title") or "").strip()
            headers = entities.get("headers") or []
            header_colors = entities.get("header_colors") or []
            name = f"Criar planilha: {title}" if title else "Criar planilha"
            steps.append({
                "module_id": "google_sheets.create_spreadsheet",
                "params": {
                    "title": title,
                    "sheet_title": entities.get("sheet_title") or "Tarefas",
                    "headers": headers,
                    "header_colors": header_colors,
                },
            })
            
        return {
            "name": name,
            "steps": self._add_step_ids(steps),
            "context": entities
        }
