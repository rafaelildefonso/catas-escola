# Backend Developer Guide

> 🐍 **Você está em:** `server/`  
> ⚡ **Stack:** Python 3.10+, FastAPI, Temporal.io

---

## 🎯 O que você precisa saber

O backend do CATAS é dividido em **duas partes** que trabalham juntas:

```
┌─────────────────────────────────────────────────────────┐
│  1. API (FastAPI) - app/                                │
│     └── Recebe requests, orquestra IA, dispara workflows│
├─────────────────────────────────────────────────────────┤
│  2. Worker (Temporal) - worker/                           │
│     └── Executa automações com resiliência             │
└─────────────────────────────────────────────────────────┘
```

### Fluxo de uma automação:

```
User: "Marcar reunião amanhã às 14h"
    ↓
[API] IntentClassifier.classify() → "calendar_create_event"
[API] EntityExtractor.extract() → {date, time, title, attendees}
[API] PayloadBuilder.build() → {tool: "google_calendar", ...}
[API] Temporal.execute_workflow(AutomationPlan)
    ↓
[Worker] AutomationWorkflow.run()
    → Activity: debit_automation_credits
    → Activity: create_event (Google Calendar)
    → Activity: send_notification
    ↓
[Supabase Realtime] → Flutter UI
```

---

## 📂 Estrutura de Pastas

```
server/
├── app/                           # 🚀 API FastAPI
│   ├── api/                       # Endpoints
│   │   ├── dependencies.py        # Auth, injeção
│   │   └── v1/                    # Versão 1
│   │       ├── chat.py            # POST /chat/message
│   │       ├── auth.py            # Login, refresh
│   │       └── integrations.py    # Google OAuth
│   │
│   ├── core/                      # ⚙️ Configurações
│   │   ├── config.py              # Settings (Pydantic)
│   │   ├── security.py            # JWT, hashing
│   │   └── firebase.py            # FCM config
│   │
│   ├── middleware/                # 🔗 Middleware
│   │   ├── auth.py                # Bearer token validation
│   │   └── cors.py                # CORS config
│   │
│   ├── models/                    # 📦 Schemas
│   │   ├── message.py             # Message schemas
│   │   └── user.py                # User schemas
│   │
│   ├── repositories/              # 🗄️ Acesso DB
│   │   ├── profiles.py            # Users, quotas
│   │   ├── chat.py                # Messages, sessions
│   │   ├── integrations.py        # OAuth tokens
│   │   └── automations.py         # Runs, logs
│   │
│   ├── routers/                   # 🛣️ Rotas (legacy)
│   │   └── *.py                   # Endpoints antigos
│   │
│   ├── services/                  # 🧠 Lógica de IA
│   │   ├── ai_service.py          # Orquestrador principal
│   │   ├── ai_base.py             # Base para providers
│   │   ├── ai_providers/          # Gemini, Groq, OpenAI
│   │   │   ├── gemini_provider.py
│   │   │   └── groq_provider.py
│   │   ├── intent_classifier.py   # Classifica intenção
│   │   ├── entity_extractor.py    # Extrai dados
│   │   ├── payload_builder.py     # Monta payload Temporal
│   │   ├── ui_components_library.py # Componentes UI
│   │   └── credit_service.py      # Gestão de créditos
│   │
│   └── main.py                    # 🚀 Entrypoint FastAPI
│
├── worker/                        # ⏱️ Temporal Worker
│   ├── activities/                # Atividades executáveis
│   │   ├── calendar/              # Google Calendar
│   │   │   └── create_calendar.py
│   │   ├── gmail/                 # Gmail
│   │   │   ├── send_gmail.py
│   │   │   └── create_draft.py
│   │   ├── google_sheets/         # Sheets
│   │   ├── flow/                  # Controle de fluxo
│   │   ├── notifications/         # Push notifications
│   │   ├── utils/                 # Helpers
│   │   └── credits.py             # Debitar créditos
│   │
│   ├── workflows/                 # Orquestrações
│   │   └── automation_workflow.py # Workflow principal
│   │
│   └── main.py                    # 🚀 Entrypoint Worker
│
├── docker/                        # 🐳 Docker
│   └── temporal/                  # Temporal Server
│       ├── docker-compose.yml
│       └── dynamicconfig/
│
├── migrations/                    # 🗄️ SQL Migrations
│   └── *.sql
│
└── tests/                         # 🧪 Testes
    └── test_*.py
```

---

## 🚀 Primeiras Tarefas

Escolha por objetivo:

| Eu quero... | Guia |
|-------------|------|
| 🆕 Entender o fluxo de IA | [Pipeline de IA](./services/ai-pipeline.md) |
| 🔌 Adicionar nova integração (Slack, Notion, etc) | [Guia: Nova Integração](../guias/nova-integracao/index.md) |
| ⚡ Criar nova atividade Temporal | [Nova Activity](./worker/nova-activity.md) |
| 🔄 Modificar workflow existente | [Modificar Workflow](./worker/modificar-workflow.md) |
| ➕ Adicionar endpoint API | [Novo Endpoint](./api/novo-endpoint.md) |
| 🧪 Escrever testes | [Testing](./testing.md) |
| 🐛 Debugar problema | [Debugging](./debugging.md) |

---

## 💡 Conceitos Chave

### 1. Pipeline de IA (Maestro)

```python
# app/services/ai_service.py

async def analyze_message(text, history, user_id):
    # 1. Classificar intenção
    intent = await intent_classifier.classify(text, history)
    
    # 2. Extrair entidades (se for ação)
    if intent != "conversation":
        entities = await entity_extractor.extract(text, intent, history)
    
    # 3. Montar payload para Temporal
    action_details = payload_builder.build(intent, entities)
    
    # 4. Retornar com componentes UI
    return {
        "text": response_text,
        "components": components,
        "action_triggered": intent != "conversation",
        "automation_id": automation_id
    }
```

### 2. Temporal: Workflows vs Activities

**Workflow** = Orquestração (o que fazer, em que ordem)
```python
# workflows/automation_workflow.py
@workflow.run
async def run(self, plan):
    # Debitar créditos
    await workflow.execute_activity(debit_automation_credits)
    
    # Executar passos do plano
    for step in plan["steps"]:
        await workflow.execute_activity(
            self._get_activity(step["module_id"]),
            args=[step["parameters"]]
        )
    
    # Notificar conclusão
    await workflow.execute_activity(send_notification)
```

**Activity** = Execução (como fazer, com retry automático)
```python
# activities/calendar/create_calendar.py
@activity.defn
async def create_event(params):
    service = _get_service(params["oauth_token"])
    event = service.events().insert(calendarId='primary', body=body).execute()
    return event
```

### 3. Sistema de Créditos

```python
# Calculado por uso de tokens
2000 tokens = 1 crédito

# Fluxo:
User manda msg → IA processa → Calcular tokens → Debitar créditos → Executar ação
```

---

## 🔧 Configurações Importantes

### Variáveis de Ambiente (.env)

```env
# === SUPABASE ===
SUPABASE_URL=                    # URL do projeto
SUPABASE_SERVICE_ROLE_KEY=       # Chave privada (server-side only!)

# === IA ===
GOOGLE_API_KEY=                  # Gemini
OPENAI_API_KEY=                  # GPT-4
GROQ_API_KEY=                     # Groq

# === TEMPORAL ===
TEMPORAL_HOST=localhost:7233     # Local: localhost, Cloud: temporal.io
TEMPORAL_NAMESPACE=default       # Local: default, Cloud: seu-namespace
TEMPORAL_TASK_QUEUE=automation-queue
TEMPORAL_TLS_CERT=               # Cloud only
TEMPORAL_TLS_KEY=                # Cloud only

# === FIREBASE ===
FIREBASE_ADMIN_SDK_JSON_PATH=    # Service account JSON

# === STRIPE ===
STRIPE_SECRET_KEY=               # Test ou Live
STRIPE_WEBHOOK_SECRET=           # Para webhooks

# === N8N (opcional) ===
N8N_WEBHOOK_URL=                 # Para prototipagem rápida
N8N_WEBHOOK_SECRET=
```

### Conexões

| Serviço | Local | Cloud |
|---------|-------|-------|
| Temporal | `localhost:7233` | `temporal.io` |
| Supabase | `supabase.co` | Self-hosted |
| Stripe | Test mode | Live mode |

---

## 📚 Tópicos Detalhados

### API (app/)
- [Pipeline de IA](./services/ai-pipeline.md) - Deep dive
- [Intent Classifier](./services/intent-classifier.md)
- [Entity Extractor](./services/entity-extractor.md)
- [Payload Builder](./services/payload-builder.md)
- [Routers e Endpoints](./api/routers.md)
- [Autenticação](./api/auth.md)
- [Créditos e Cobrança](./api/credits.md)
- [Repositories](./repositories.md) - Padrões de acesso

### Worker (worker/)
- [Conceitos Temporal](./worker/temporal-concepts.md)
- [Workflow Principal](./worker/automation-workflow.md)
- [Nova Atividade](./worker/nova-activity.md)
- [Modificar Workflow](./worker/modificar-workflow.md)
- [Debugging](./worker/debugging.md)
- [Atividades Existentes](./worker/activities-list.md)

### IA (app/services/)
- [AI Providers](./services/ai-providers.md) - Gemini, Groq, OpenAI
- [Prompt Engineering](./services/prompts.md)
- [UI Components](./services/ui-components.md)
- [Error Handling](./services/error-handling.md)

### Avançado
- [Testes](./testing.md) - Unit, integration, e2e
- [Performance](./performance.md)
- [Deploy](./deploy.md) - Produção checklists

---

## 🔗 Links Rápidos

| Recurso | Local |
|---------|-------|
| 📁 Código API | `server/app/` |
| 📁 Código Worker | `server/worker/` |
| 🧪 Testes | `server/tests/` |
| ⚙️ Config | `server/.env` |
| ⏱️ Temporal UI | http://localhost:8080 |
| 📚 API Docs | http://localhost:8000/docs |

---

## 🆘 Precisa de ajuda?

1. **Worker não conecta?** → Verifique `TEMPORAL_HOST` e se Docker está rodando
2. **Erro de autenticação?** → Verifique `SUPABASE_SERVICE_ROLE_KEY`
3. **IA não responde?** → Verifique `GOOGLE_API_KEY` ou quota
4. **Mais problemas?** → [Debugging Guide](./debugging.md)

---

> ⬅️ [Voltar para Documentação](../index.md)  
> ➡️ [Próximo: Pipeline de IA →](./services/ai-pipeline.md)
