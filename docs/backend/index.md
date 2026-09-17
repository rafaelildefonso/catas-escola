# Backend Developer Guide

> **Voce esta em:** `backend/`  
> **Stack:** Python 3.11+, Flask, SQLAlchemy, FastAPI (Worker)

---

## O que voce precisa saber

O backend do CATAS e dividido em **duas partes** que trabalham juntas:

```
  1. API (Flask) - backend/application.py
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
├── application.py         # create_app(), init_firebase()
├── routes.py              # Rotas centralizadas (~112 endpoints)
├── extensions.py          # db = SQLAlchemy()
├── run.py                 # Entry point da API
├── models/                # 18 models SQLAlchemy
├── controllers/           # 24 controllers
├── services/              # 24 pastas, ~120 arquivos
├── repositories/          # 8 repositories
├── core/                  # Config, security, OAuth
├── worker/                # FastAPI worker
├── tests/                 # 11 arquivos de teste
├── migrations/            # 20+ migrations SQL
├── docker-compose.yml     # Docker config
├── Dockerfile             # API container
└── Dockerfile.worker      # Worker container
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

### 1. Pipeline de IA (Multi-Agente)

```python
# backend/services/ia/ai_service.py

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
# worker/modules/google_calendar_modules.py
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
from extensions import db

def get_user_profile(user_id: str) -> dict | None:
    profile = Profile.query.filter(Profile.id == user_id).first()
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
- [API Reference](./api-referencia.md) - Todos os endpoints
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
