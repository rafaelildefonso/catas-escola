import json


class ErroPermissao(Exception):
    """Erro de regra de negócio que deve ser respondido com HTTP 403."""
    pass


class ErroNaoEncontrado(Exception):
    """Recurso não encontrado ou sem posse do usuário (HTTP 404)."""
    pass


MENSAGENS_ONBOARDING = [
    "CATAS: quero criar minha primeira automação de demonstração — um lembrete simples para começar.",
    "CATAS: Quero organizar meus leads do Zap Imóveis no Google Sheets e enviar um e-mail de boas-vindas automático.",
    "CATAS: Quero consolidar os dados das minhas campanhas em uma planilha do Google Sheets e gerar um relatório resumido com IA.",
    "CATAS: Quero resumir meus processos jurídicos em PDF e criar tarefas de acompanhamento no meu calendário.",
]

LIMITE_CHUNKS_CONTINUACAO = 15


def montar_mensagem_interna(component_type: str, response_data: dict) -> str:
    """Traduz a resposta de um componente interativo em mensagem interna do usuário."""
    mapa = {
        "action_approval": "[APROVADO]" if response_data.get("approved") else "[RECUSADO]",
        "contact_select": f"[CONTATOS SELECIONADOS] {','.join(response_data.get('selected_contacts', []))}",
        "date_time_picker": f"[DATA_HORA_SELECIONADA] {response_data.get('iso_date')}",
        "multiple_choice": f"[ESCOLHA] {response_data.get('selected_option')}",
        "text_input": f"[TEXTO_INPUT] {response_data.get('text')}",
    }
    return mapa.get(component_type, f"[RESPOSTA_COMPONENTE] {json.dumps(response_data)}")
