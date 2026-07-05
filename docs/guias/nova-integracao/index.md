# Guia: Adicionar Nova Integracao

> **Meta:** Adicionar suporte a um novo servico (ex: Slack, Notion, Asana)  
> **Tempo estimado:** 2-4 horas  
> **Stack:** Python, Worker Modules

---

## Resumo do Processo

Para adicionar uma nova integracao (exemplo: Slack), voce precisa:

1. **Criar modulo no Worker** - Executar a acao
2. **Registrar no Runner** - Tornar o modulo disponivel
3. **Atualizar Entity Extractor** - IA entender o comando
4. **Criar UI Component** (opcional) - Preview no Flutter
5. **Testar end-to-end**

---

## Passo a Passo

### Passo 1: Criar Modulo no Worker

**Onde:** `backend/worker/modules/slack/`

```python
# backend/worker/modules/slack/send_message.py

def execute(params: dict) -> dict:
    """
    Envia mensagem para canal do Slack.
    
    Args:
        params: {
            "oauth_token": "xoxb-...",
            "channel": "#geral",
            "message": "Ola equipe!"
        }
    
    Returns:
        {"message_id": "123", "ok": True}
    """
    from slack_sdk import WebClient
    from slack_sdk.errors import SlackApiError
    
    client = WebClient(token=params["oauth_token"])
    
    result = client.chat_postMessage(
        channel=params["channel"],
        text=params["message"]
    )
    
    return {
        "ok": True,
        "message_id": result["ts"],
        "channel": result["channel"]
    }
```

### Passo 2: Registrar no Runner

**Onde:** `backend/worker/runner.py`

```python
# Mapear o novo modulo
MODULE_MAP = {
    # ... existentes
    "google_calendar.create": "modules.google_calendar",
    "gmail.send": "modules.gmail",
    "slack.send_message": "modules.slack.send_message",  # Adicionar
}
```

### Passo 3: Atualizar Entity Extractor

**Onde:** `backend/services/entity_extractor.py`

Adicione um novo case no prompt:

```python
if intent == "slack_send_message":
    system_prompt = """
    Extraia para enviar mensagem no Slack:
    - channel: canal (ex: #geral, @usuario)
    - message: texto da mensagem
    - thread_ts: opcional, ID da thread
    
    Exemplo:
    "Postar no #marketing: Lancamento amanha!"
    
    Output:
    {
        "channel": "#marketing",
        "message": "Lancamento amanha!"
    }
    """
```

**Atualizar IntentClassifier:**

```python
# backend/services/intent_classifier.py
# Adicionar ao prompt de classificacao:
"""
Intencoes disponiveis:
- conversation
- calendar_create_event
- task_create
- email_draft
- slack_send_message    # Adicionar
"""
```

### Passo 4: Payload Builder

**Onde:** `backend/services/payload_builder.py`

```python
def build_payload(intent: str, entities: dict) -> dict:
    if intent == "slack_send_message":
        return {
            "tool": "slack",
            "action": "send_message",
            "parameters": {
                "channel": entities.get("channel"),
                "message": entities.get("message"),
            },
            "required_auth": "slack"  # Para buscar OAuth token
        }
```

### Passo 5: UI Component (Opcional)

Se quiser mostrar preview antes de executar:

```dart
// app_flutter/lib/components/ai_components/preview_slack_message.dart
class PreviewSlackMessage extends StatelessWidget {
  final String channel;
  final String message;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("# $channel", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(message),
        ],
      ),
    );
  }
}
```

**Registrar no Flutter:**

```dart
// ChatProvider ou similar
switch (componentType) {
  case 'preview_slack_message':
    return PreviewSlackMessage(
      channel: data['channel'],
      message: data['message'],
    );
}
```

### Passo 6: OAuth Integration

Se precisar de autenticacao OAuth:

**Backend - Adicionar ao enum:**

```python
# backend/models/integration.py
class IntegrationProvider(str, Enum):
    GOOGLE = "google"
    SLACK = "slack"  # Adicionar
```

**Frontend - Adicionar botao:**

```dart
// Tela de integracoes
IntegrationButton(
  provider: 'slack',
  icon: Icons.chat,
  label: 'Slack',
  onTap: () => _connectSlack(),
)
```

---

## Testando a Integracao

### 1. Teste Unitario

```python
# backend/tests/modules/test_slack.py
import pytest
from worker.modules.slack.send_message import execute

def test_send_slack_message():
    # Teste com mock
    result = execute({
        "oauth_token": "xoxb-test",
        "channel": "#test",
        "message": "Hello"
    })
    
    assert result["ok"] is True
    assert "message_id" in result
```

### 2. Teste End-to-End

```bash
# 1. Subir backend e worker
cd backend
flask run --port 8000 --debug
# Outro terminal: python -m worker.server

# 2. Testar via API
curl -X POST http://localhost:8000/api/v1/chat/message \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dev-token" \
  -d '{"message": "Enviar no Slack #geral: Reuniao confirmada!"}'

# 3. Verificar resposta inclui componentes corretos
```

---

## Arquivos Criados/Modificados

| Arquivo | Acao | Descricao |
|---|---|---|
| `worker/modules/slack/*.py` | Criar | Novo modulo |
| `worker/runner.py` | Modificar | Registrar modulo |
| `services/entity_extractor.py` | Modificar | Novo prompt |
| `services/intent_classifier.py` | Modificar | Nova intencao |
| `services/payload_builder.py` | Modificar | Novo payload |
| `models/integration.py` | Modificar | Novo provider |
| `app_flutter/lib/components/...` | Criar | UI component |

---

## Checklist

- [ ] Modulo criado e registrado
- [ ] Entity Extractor entende o comando
- [ ] Payload Builder monta parametros corretos
- [ ] UI Component criado (se aplicavel)
- [ ] OAuth configurado (se aplicavel)
- [ ] Testes passando
- [ ] Documentado

---

## Problemas Comuns

### "Module not found"
Verifique se importou o modulo no `runner.py` e se o caminho esta correto.

### "IA nao entende o comando"
- Verifique o prompt no EntityExtractor
- Adicione exemplos few-shot
- Teste com variacoes do comando

### "OAuth falha"
- Verifique se provider esta no enum
- Verifique scopes do OAuth
- Verifique se token esta criptografado corretamente

---

> [Voltar para Guias](../index.md)  
> [Debugging ](../debugging/index.md)
