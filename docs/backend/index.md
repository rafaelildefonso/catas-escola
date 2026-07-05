# Backend Developer Guide

> **Voce esta em:** `backend/`  
> **Stack:** Python 3.10+, Flask, SQLAlchemy, FastAPI (Worker)

---

## O que voce precisa saber

O backend do CATAS e dividido em **duas partes** que trabalham juntas:

```
  1. API (Flask) - backend/app.py
      Recebe requests, orquestra IA, gerencia usuarios
  2. Worker (FastAPI) - backend/worker/
      Executa automacoes com resiliencia
```

### Fluxo de uma automacao:

```
User: "Marcar reuniao amanha as 14h"
    |
[API] IntentClassifier.classify()  "calendar_create_event"
[API] EntityExtractor.extract()  {date, time, title, attendees}
[API] PayloadBuilder.build()  {tool: "google_calendar", ...}
[API] POST /worker/execute
    |
[Worker] AutomationRunner.run()
    Module: debit_automation_credits
    Module: create_event (Google Calendar)
    Module: send_notification
    |
[Database] SQLAlchemy  Flutter UI
```

---

## Estrutura de Pastas

```
backend/
  app.py                           #  API Flask
  core/
    config.py                      # Configuracoes
    security.py                    # Auth (Supabase JWT)
    errors.py                      # Error handling
  controllers/                     # Blueprints Flask
    user.py                        # Perfil, quotas
    chat.py                        # Sessoes de chat
    chatbot.py                     # POST /api/v1/chat/message
    automations.py                 # Automacoes CRUD
    integrations.py                # Google OAuth
    payments.py                    # Stripe
    feedback.py                    # Feedback do usuario
    webhooks.py                    # Webhooks Stripe
    webhook_receiver.py            # Webhooks externos
    prompt_improve.py              # Melhoria de prompt
  models/
    db_models.py                   # Modelos SQLAlchemy (17 tabelas)
  services/
    database.py                    # SQLAlchemy engine, SessionLocal
    ai_service.py                  # Orquestrador principal
    ai_base.py                    # Base para providers
    ai_providers/                  # Gemini, Groq, OpenAI
      gemini_provider.py
      groq_provider.py
    intent_classifier.py           # Classifica intencao
    entity_extractor.py            # Extrai dados
    payload_builder.py             # Monta payload
    ui_components_library.py       # Componentes UI
    credit_service.py              # Gestao de creditos (atomic)
    ia_memory.py                   # Busca semantica (pgvector)
    notification_service.py        # Push notifications (FCM)
  repositories/                    # Acesso a dados (SQLAlchemy)
    profiles.py                    # Perfis, quotas
    chat.py                        # Mensagens, sessoes
    automations.py                 # Runs, logs
    automation_logs.py
    automation_generation_logs.py
    integrations.py                # OAuth tokens
    feedback.py
    ai_suggestions.py
    page_contexts.py
  worker/                          #  Worker FastAPI
    server.py                      # Servidor FastAPI
    runner.py                      # Motor de execucao
    modules/                       # Modulos executaveis
      http_request.py              # Requisicoes HTTP
      google_calendar.py           # Google Calendar
      gmail.py                     # Gmail
      google_sheets.py             # Google Sheets
      google_drive.py              # Google Drive
      google_docs.py               # Google Docs
      ai_transform.py              # Transformacao com IA
      flow_control.py              # Controle de fluxo
  migrations/                      #  SQL Migrations
    *.sql
  tests/                           #  Testes
    test_*.py
  requirements.txt
  .env
```

---

## Primeiras Tarefas

Escolha por objetivo:

| Eu quero... | Guia |
|-------------|------|
| Entender o fluxo de IA | [Pipeline de IA](./ia-pipeline.md) |
| Adicionar nova integracao (Slack, Notion, etc) | [Guia: Nova Integracao](../guias/nova-integracao/index.md) |
| Adicionar modulo ao Worker | [Novo Modulo](./worker/novo-modulo.md) |
| Adicionar endpoint API | [Novo Endpoint](./api/novo-endpoint.md) |
| Escrever testes | [Testing](./testing.md) |
| Depurar problema | [Debugging](../guias/debugging/index.md) |

---

## Conceitos Chave

### 1. Pipeline de IA (Maestro)

```python
# backend/services/ai_service.py

def analyze_message(text, history, user_id):
    # 1. Classificar intencao
    intent = intent_classifier.classify(text, history)
    
    # 2. Extrair entidades (se for acao)
    if intent != "conversation":
        entities = entity_extractor.extract(text, intent, history)
    
    # 3. Montar payload para Worker
    action_details = payload_builder.build(intent, entities)
    
    # 4. Retornar com componentes UI
    return {
        "text": response_text,
        "components": components,
        "action_triggered": intent != "conversation",
        "automation_id": automation_id
    }
```

### 2. Worker: Runner + Modulos

**Runner** = Orquestracao (o que fazer, em que ordem)
```python
# worker/runner.py
class AutomationRunner:
    def execute(self, plan):
        # Debitar creditos
        self.run_module("credits.debit", plan["user_id"])
        
        # Executar passos do plano
        for step in plan["steps"]:
            self.run_module(step["module_id"], step["parameters"])
        
        # Notificar conclusao
        self.run_module("notification.send", plan["user_id"])
```

**Modulo** = Execucao (como fazer)
```python
# worker/modules/google_calendar.py
def execute(params):
    service = get_google_service(params["oauth_token"])
    event = service.events().insert(calendarId='primary', body=body).execute()
    return event
```

### 3. Sistema de Creditos

```python
# Calculado por uso de tokens
2000 tokens = 1 credito

# Fluxo:
User manda msg  IA processa  Calcular tokens  Debitar creditos  Executar acao
```

### 4. Acesso a Dados (SQLAlchemy)

```python
# repositories/profiles.py
from services.database import get_sync_db

def get_user_profile(user_id: str) -> dict | None:
    with get_sync_db() as db:
        profile = db.query(Profile).filter(Profile.id == user_id).first()
        return profile.to_dict() if profile else None
```

---

## Configuracoes Importantes

### Variaveis de Ambiente (.env)

```env
# === SUPABASE (auth) ===
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=

# === DATABASE (SQLAlchemy) ===
DATABASE_URL=

# === IA ===
GROQ_API_KEY=
GOOGLE_API_KEY=
OPENAI_API_KEY=

# === FIREBASE ===
FIREBASE_ADMIN_SDK_JSON_PATH=

# === STRIPE ===
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=

# === WORKER ===
WORKER_URL=http://localhost:8001
```

---

## Topicos Detalhados

### API
- [Pipeline de IA](./ia-pipeline.md) - Deep dive
- [Intent Classifier](./services/intent-classifier.md)
- [Entity Extractor](./services/entity-extractor.md)
- [Payload Builder](./services/payload-builder.md)
- [Autenticacao](./api/auth.md)
- [Creditos e Cobranca](./api/credits.md)
- [Repositories](./repositories.md) - Padroes de acesso

### Worker
- [Worker Runner](./worker/runner.md)
- [Modulos Existentes](./worker/modules-list.md)
- [Novo Modulo](./worker/novo-modulo.md)

### IA
- [AI Providers](./services/ai-providers.md) - Gemini, Groq, OpenAI
- [Prompt Engineering](./services/prompts.md)
- [UI Components](./services/ui-components.md)
- [Error Handling](./services/error-handling.md)

### Avancado
- [Testes](./testing.md) - Unit, integration, e2e
- [Performance](./performance.md)
- [Deploy](./deploy.md) - Producao checklists

---

## Links Rapidos

| Recurso | Local |
|---------|-------|
| Codigo API | `backend/` |
| Codigo Worker | `backend/worker/` |
| Testes | `backend/tests/` |
| Config | `backend/.env` |
| API Docs | http://localhost:8000/ |

---

## Precisa de ajuda?

1. **Erro de autenticacao?**  Verifique `SUPABASE_SERVICE_ROLE_KEY`
2. **IA nao responde?**  Verifique `GROQ_API_KEY` ou quota
3. **Worker nao conecta?**  Verifique `WORKER_URL`
4. **Mais problemas?**  [Debugging Guide](../guias/debugging/index.md)

---

> [Voltar para Documentacao](../index.md)  
> [Proximo: Pipeline de IA ](./ia-pipeline.md)
