# Guia: Adicionar Nova Integração

> 🎯 **Meta:** Adicionar suporte a um novo serviço (ex: Slack, Notion, Asana)  
> ⏱️ **Tempo estimado:** 2-4 horas  
> 🐍 **Stack:** Python, Temporal

---

## 📋 Resumo do Processo

Para adicionar uma nova integração (exemplo: Slack), você precisa:

1. **Criar Activity Temporal** - Executar a ação
2. **Adicionar ao Workflow** - Orquestrar a execução
3. **Atualizar Entity Extractor** - IA entender o comando
4. **Criar UI Component** (opcional) - Preview no Flutter
5. **Testar end-to-end**

---

## 🚀 Passo a Passo

### Passo 1: Criar Activity Temporal

**Onde:** `server/worker/activities/slack/`

```python
# server/worker/activities/slack/send_message.py
from temporalio import activity
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

@activity.defn
async def send_slack_message(params: dict) -> dict:
    """
    Envia mensagem para canal do Slack.
    
    Args:
        params: {
            "oauth_token": "xoxb-...",
            "channel": "#geral",
            "message": "Olá equipe!"
        }
    
    Returns:
        {"message_id": "123", "ok": True}
    """
    try:
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
        
    except SlackApiError as e:
        raise activity.ApplicationError(f"Slack API error: {e.response['error']}")
```

**Registre no Worker:**

```python
# server/worker/main.py
from activities.slack.send_message import send_slack_message

worker = Worker(
    ...
    activities=[
        # ... outras atividades
        send_slack_message,  # ⬅️ Adicionar aqui
    ],
)
```

---

### Passo 2: Adicionar ao Workflow

**Onde:** `server/worker/workflows/automation_workflow.py`

```python
# Mapear o novo módulo
ACTIVITY_MAP = {
    # ... existentes
    "google_calendar.create": create_event,
    "gmail.send": send_email,
    "slack.send_message": send_slack_message,  # ⬅️ Adicionar
}
```

**Testar integração:**

```python
# Criar plano de teste
plan = {
    "steps": [
        {
            "step_index": 1,
            "module_id": "slack.send_message",
            "parameters": {
                "oauth_token": "xoxb-test",
                "channel": "#test",
                "message": "Teste de integração"
            }
        }
    ]
}
```

---

### Passo 3: Atualizar Entity Extractor

**Onde:** `server/app/services/entity_extractor.py`

Adicione um novo case no prompt:

```python
# No método extract_entities
if intent == "slack_send_message":
    system_prompt = """
    Extraia para enviar mensagem no Slack:
    - channel: canal (ex: #geral, @usuario)
    - message: texto da mensagem
    - thread_ts: opcional, ID da thread
    
    Exemplo:
    "Postar no #marketing: Lançamento amanhã!"
    
    Output:
    {
        "channel": "#marketing",
        "message": "Lançamento amanhã!"
    }
    """
```

**Atualizar IntentClassifier:**

```python
# server/app/services/intent_classifier.py
# Adicionar ao prompt de classificação:
"""
Intenções disponíveis:
- conversation
- calendar_create_event
- task_create
- email_draft
- slack_send_message    # ⬅️ Adicionar
"""
```

---

### Passo 4: Payload Builder

**Onde:** `server/app/services/payload_builder.py`

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

---

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

---

### Passo 6: OAuth Integration

Se precisar de autenticação OAuth:

**Backend - Adicionar ao enum:**

```python
# server/app/models/integration.py
class IntegrationProvider(str, Enum):
    GOOGLE = "google"
    SLACK = "slack"  # ⬅️ Adicionar
```

**Frontend - Adicionar botão:**

```dart
// Tela de integrações
IntegrationButton(
  provider: 'slack',
  icon: Icons.chat,
  label: 'Slack',
  onTap: () => _connectSlack(),
)
```

---

## 🧪 Testando a Integração

### 1. Teste Unitário

```python
# server/tests/activities/test_slack.py
import pytest
from worker.activities.slack.send_message import send_slack_message

@pytest.mark.asyncio
async def test_send_slack_message():
    result = await send_slack_message({
        "oauth_token": "xoxb-test",
        "channel": "#test",
        "message": "Hello"
    })
    
    assert result["ok"] is True
    assert "message_id" in result
```

### 2. Teste End-to-End

```bash
# 1. Subir tudo
docker-compose up -d
cd server && uvicorn app.main:app --reload
# Outro terminal: python worker/main.py

# 2. Testar via API
POST /api/v1/chat/message
{
  "message": "Enviar no Slack #geral: Reunião confirmada!"
}

# 3. Verificar resposta inclui componentes corretos
```

---

## 📂 Arquivos Criados/Modificados

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| `worker/activities/slack/*.py` | Criar | Nova atividade |
| `worker/main.py` | Modificar | Registrar atividade |
| `worker/workflows/automation_workflow.py` | Modificar | Adicionar ao mapa |
| `app/services/entity_extractor.py` | Modificar | Novo prompt |
| `app/services/intent_classifier.py` | Modificar | Nova intenção |
| `app/services/payload_builder.py` | Modificar | Novo payload |
| `app/models/integration.py` | Modificar | Novo provider |
| `app_flutter/lib/components/...` | Criar | UI component |

---

## ✅ Checklist

- [ ] Activity criada e registrada
- [ ] Workflow mapeia o novo módulo
- [ ] Entity Extractor entende o comando
- [ ] Payload Builder monta parâmetros corretos
- [ ] UI Component criado (se aplicável)
- [ ] OAuth configurado (se aplicável)
- [ ] Testes passando
- [ ] Documentado

---

## 🆘 Problemas Comuns

### "Module not found"
Verifique se importou a activity no `worker/main.py`

### "Activity not registered"
Verifique se adicionou ao ACTIVITY_MAP no workflow

### "IA não entende o comando"
- Verifique o prompt no EntityExtractor
- Adicione exemplos few-shot
- Teste com variações do comando

### "OAuth falha"
- Verifique se provider está no enum
- Verifique scopes do OAuth
- Verifique se token está criptografado corretamente

---

> ⬅️ [Voltar para Guias](../index.md)  
> ➡️ [Debugging →](../debugging/index.md)
