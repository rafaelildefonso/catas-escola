import os
from datetime import datetime, timedelta


class MontarPlanoOnboardingService:
    """Monta o plano de automação da demonstração de onboarding (calendário + pasta + planilha)."""

    @staticmethod
    def executar(client_name: str, meeting_date: str, meeting_time: str, user_id: str) -> dict:
        sheet_id = os.getenv("DEMO_CLIENTES_SPREADSHEET_ID", "")
        parent_folder_id = os.getenv("DEMO_CLIENTES_FOLDER_ID", "")

        start_dt = f"{meeting_date}T{meeting_time}:00"
        end_dt = (datetime.fromisoformat(start_dt) + timedelta(hours=1)).isoformat()

        steps = [{
            "step_id": "agendar_reuniao",
            "module_id": "google_calendar.create_event",
            "params": {
                "summary": f"Onboarding {client_name}",
                "start": start_dt,
                "end": end_dt,
                "description": f"Reunião de onboarding com {client_name}",
            },
        }]

        if parent_folder_id:
            steps.append({
                "step_id": "criar_pasta",
                "module_id": "google_drive.create_folder",
                "params": {
                    "folder_name": client_name,
                    "parent_folder_id": parent_folder_id,
                },
            })

        if sheet_id:
            steps.append({
                "step_id": "registrar_cliente",
                "module_id": "google_sheets.append_row",
                "params": {
                    "spreadsheet_id": sheet_id,
                    "range": "Sheet1!A:C",
                    "values": [[client_name, meeting_date, f"Onboarding {meeting_time}"]],
                },
            })

        return {
            "name": f"Onboarding de {client_name}",
            "steps": steps,
            "context": {
                "client_name": client_name,
                "user_id": user_id,
            },
        }
