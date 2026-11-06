from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional

@dataclass
class ModuleSpec:
    module_id: str
    name: str
    description: str
    category: str  # messaging, calendar, sheets, flow
    provider: Optional[str] = None  # google_gmail, google_calendar, etc.
    required_params: List[str] = field(default_factory=list)
    output_keys: List[str] = field(default_factory=list)

MODULE_REGISTRY: Dict[str, ModuleSpec] = {
    # Gmail
    "gmail.send_email": ModuleSpec(
        module_id="gmail.send_email",
        name="Enviar E-mail",
        description="Envia um e-mail via Gmail",
        category="messaging",
        provider="google_gmail",
        required_params=["to", "subject", "body"],
        output_keys=["message_id", "thread_id"]
    ),
    "gmail.create_draft": ModuleSpec(
        module_id="gmail.create_draft",
        name="Criar Rascunho",
        description="Cria um rascunho de e-mail",
        category="messaging",
        provider="google_gmail",
        required_params=["to", "subject", "body"]
    ),
    "gmail.get_unread_emails": ModuleSpec(
        module_id="gmail.get_unread_emails",
        name="Buscar E-mails Não Lidos",
        description="Busca e-mails não lidos na caixa de entrada",
        category="messaging",
        provider="google_gmail",
        output_keys=["emails"]
    ),

    # Calendar
    "google_calendar.create_event": ModuleSpec(
        module_id="google_calendar.create_event",
        name="Agendar Evento",
        description="Cria um novo evento no Google Calendar",
        category="calendar",
        provider="google_calendar",
        required_params=["summary", "start", "end"],
        output_keys=["event_id", "html_link"]
    ),
    "google_calendar.list_events": ModuleSpec(
        module_id="google_calendar.list_events",
        name="Listar Eventos do Calendário",
        description="Lista eventos do Google Calendar. Suporta filtros por período (time_min, time_max) e busca por texto (query)",
        category="calendar",
        provider="google_calendar",
        required_params=[],
        output_keys=["events", "count"]
    ),
    "google_calendar.update_event": ModuleSpec(
        module_id="google_calendar.update_event",
        name="Atualizar Evento",
        description="Atualiza campos de um evento existente no Google Calendar (resumo, horário, local, descrição)",
        category="calendar",
        provider="google_calendar",
        required_params=["event_id"],
        output_keys=["event_id", "summary", "html_link"]
    ),
    "google_calendar.delete_event": ModuleSpec(
        module_id="google_calendar.delete_event",
        name="Deletar Evento",
        description="Remove um evento do Google Calendar pelo seu ID",
        category="calendar",
        provider="google_calendar",
        required_params=["event_id"],
        output_keys=["event_id", "deleted"]
    ),

    # Sheets
    "google_sheets.append_row": ModuleSpec(
        module_id="google_sheets.append_row",
        name="Adicionar Linha na Planilha",
        description="Adiciona dados em uma nova linha de uma planilha Google Sheets",
        category="sheets",
        provider="google_sheets",
        required_params=["spreadsheet_id", "range", "values"],
        output_keys=["updated_range", "updated_rows"]
    ),
    "google_sheets.get_values": ModuleSpec(
        module_id="google_sheets.get_values",
        name="Ler Dados da Planilha",
        description="Lê dados de um intervalo de células de uma planilha Google Sheets (ex: Sheet1!A1:C10)",
        category="sheets",
        provider="google_sheets",
        required_params=["spreadsheet_id", "range"],
        output_keys=["values", "row_count"]
    ),
    "google_sheets.update_values": ModuleSpec(
        module_id="google_sheets.update_values",
        name="Atualizar Células da Planilha",
        description="Atualiza valores em células específicas de uma planilha Google Sheets",
        category="sheets",
        provider="google_sheets",
        required_params=["spreadsheet_id", "range", "values"],
        output_keys=["updated_range", "updated_cells"]
    ),
    "google_sheets.create_spreadsheet": ModuleSpec(
        module_id="google_sheets.create_spreadsheet",
        name="Criar Planilha",
        description="Cria uma nova planilha no Google Sheets com um título definido",
        category="sheets",
        provider="google_sheets",
        required_params=["title"],
        output_keys=["spreadsheet_id", "spreadsheet_url"]
    ),

    # Drive
    "google_drive.list_files": ModuleSpec(
        module_id="google_drive.list_files",
        name="Listar Arquivos do Drive",
        description="Lista arquivos no Google Drive. Suporta busca por nome (query) e filtro por pasta (folder_id)",
        category="storage",
        provider="google_drive",
        required_params=[],
        output_keys=["files", "count"]
    ),
    "google_drive.upload_file": ModuleSpec(
        module_id="google_drive.upload_file",
        name="Enviar Arquivo para o Drive",
        description="Faz upload de um arquivo de texto ou dados para o Google Drive",
        category="storage",
        provider="google_drive",
        required_params=["file_name", "file_content"],
        output_keys=["file_id", "web_link"]
    ),
    "google_drive.get_file_content": ModuleSpec(
        module_id="google_drive.get_file_content",
        name="Ler Conteúdo de Arquivo do Drive",
        description="Lê o conteúdo textual de um arquivo do Google Drive (compatível com Docs, Sheets exportados, TXT, CSV)",
        category="storage",
        provider="google_drive",
        required_params=["file_id"],
        output_keys=["content", "file_name"]
    ),
    "google_drive.create_folder": ModuleSpec(
        module_id="google_drive.create_folder",
        name="Criar Pasta no Drive",
        description="Cria uma nova pasta no Google Drive",
        category="storage",
        provider="google_drive",
        required_params=["folder_name"],
        output_keys=["folder_id", "folder_name", "web_link"]
    ),

    # Reports
    "report.generate_pdf": ModuleSpec(
        module_id="report.generate_pdf",
        name="Gerar relatório em PDF",
        description=(
            "Organiza dados de uma planilha, calcula indicadores, cria um gráfico e "
            "salva o PDF na página Relatórios do CATAS"
        ),
        category="reports",
        required_params=["title", "data"],
        output_keys=["report_id", "title", "format", "rows_analyzed"],
    ),

    # Flow
    "flow.wait": ModuleSpec(
        module_id="flow.wait",
        name="Aguardar",
        description="Pausa a automação por um tempo determinado",
        category="flow",
        required_params=["duration"]
    ),
    "flow.condition": ModuleSpec(
        module_id="flow.condition",
        name="Condição (IF)",
        description="Ramifica o fluxo baseado em uma condição lógica",
        category="flow",
        required_params=["variable", "operator", "value"]
    )
}


def get_module_spec(module_id: str) -> Optional[ModuleSpec]:
    return MODULE_REGISTRY.get(module_id)

def get_full_catalog() -> List[Dict[str, Any]]:
    """Retorna o catálogo completo formatado para ser consumido pela IA/MCP."""
    return [
        {
            "id": m.module_id,
            "name": m.name,
            "description": m.description,
            "category": m.category,
            "required_params": m.required_params,
            "provider": m.provider
        }
        for m in MODULE_REGISTRY.values()
    ]
