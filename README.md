# CATAS (Centralized Agent Task Automation System)

## Equipe

- Rafael Ildefonso Furtado
- Lucas Salman Resende
- Henrique Santos Tavares
- Miguel Teixeira Valadao
- Lucas Nunes Araujo

Agente de Automação Inteligente baseado em Linguagem Natural que **executa ações** no mundo real através de uma interface de chat multiplataforma.

## Arquitetura

- **Client (Flutter):** Interface multiplataforma (Mobile/Desktop)
- **Core API (Flask):** Processa linguagem natural com IA multi-agente
- **Executor (Temporal.io):** Workflows duráveis para integrações com Google APIs

## Tech Stack

| Camada | Tecnologia |
|--------|-----------|
| Frontend | Flutter (Dart) - Android, iOS, Web, Desktop |
| Backend | Python 3.11+, Flask + SQLAlchemy |
| AI | Groq, OpenAI, Google Gemini |
| Database | Supabase (PostgreSQL) ou SQLite (dev) |
| Workflows | Temporal.io |
| Auth | Supabase Auth + Firebase |

---

## Quick Start (Recomendado)

### Pré-requisitos
- Python 3.11+
- Conta Supabase + credenciais de API

### 1. Configurar .env

```bash
cd backend
cp .env.example .env
# Edite com suas credenciais (ou deixe DATABASE_URL vazio para SQLite local)
```

### 2. Rodar a API

```bash
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
python run.py
```

API: http://localhost:8000 | Health: http://localhost:8000/health

### 3. Rodar o Worker (opcional, para automações)

```bash
cd backend
.\venv\Scripts\activate
python -m worker.server
```

### Usando o Script de Atalho

```powershell
.\run_catas.ps1          # Só API
.\run_catas.ps1 -Mode worker   # Só Worker
.\run_catas.ps1 -Mode all      # API + Worker
```

---

## Rodando o Flutter App

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 52159
```

## Models Implementadas (CRUD Completo)

Todas as 17 Models do domínio estão implementadas na camada `backend/app/models/`, herdando de `db.Model` com métodos `salvar()`, `atualizar()`, `deletar()`, `listar_todos()`, `buscar_por_id()` e `to_dict()`.

| # | Model | Tabela | Descrição |
|---|-------|--------|-----------|
| 1 | **Profile** | `profiles` | Perfil do usuário, assinatura, cotas |
| 2 | **ChatSession** | `chat_sessions` | Sessões de chat do usuário |
| 3 | **Message** | `messages` | Mensagens do chat (usuário/assistente) |
| 4 | **Automation** | `automations` | Definições de automação |
| 5 | **AutomationRun** | `automation_runs` | Execuções de automação |
| 6 | **AutomationStepLog** | `automation_step_logs` | Logs por passo da automação |
| 7 | **AutomationGenerationLog** | `automation_generation_logs` | Auditoria do planner de IA |
| 8 | **ExecutionLog** | `execution_logs` | Logs legados de execução |
| 9 | **Integration** | `integrations` | Tokens OAuth de integrações |
| 10 | **MessageFeedback** | `message_feedback` | Feedback do usuário nas mensagens |
| 11 | **AiSuggestion** | `ai_suggestions` | Sugestões proativas de IA |
| 12 | **PageContext** | `page_contexts` | Contexto de página analisada |
| 13 | **BrowserSession** | `browser_sessions` | Sessões ativas do navegador |
| 14 | **PageAnalysisCache** | `page_analysis_cache` | Cache de análise de URLs |
| 15 | **UserDevice** | `user_devices` | Tokens FCM para push notification |
| 16 | **UserWebhookConfig** | `user_webhook_configs` | Configurações de webhook |
| 17 | **IaMemory** | `ia_memory` | Memória semântica (RAG) |

## Rotas da API (85 Endpoints CRUD)

Cada Model possui 5 endpoints REST no padrão `/api/v1/<recursos>`:

| Model | GET (listar) | GET (buscar) | POST (criar) | PUT (atualizar) | DELETE (deletar) |
|-------|-------------|--------------|-------------|-----------------|------------------|
| Profile | `GET /api/v1/profiles` | `GET /api/v1/profiles/<id>` | `POST /api/v1/profiles` | `PUT /api/v1/profiles/<id>` | `DELETE /api/v1/profiles/<id>` |
| ChatSession | `GET /api/v1/chat-sessions` | `GET /api/v1/chat-sessions/<id>` | `POST /api/v1/chat-sessions` | `PUT /api/v1/chat-sessions/<id>` | `DELETE /api/v1/chat-sessions/<id>` |
| Message | `GET /api/v1/messages` | `GET /api/v1/messages/<id>` | `POST /api/v1/messages` | `PUT /api/v1/messages/<id>` | `DELETE /api/v1/messages/<id>` |
| Automation | `GET /api/v1/automations` | `GET /api/v1/automations/<id>` | `POST /api/v1/automations` | `PUT /api/v1/automations/<id>` | `DELETE /api/v1/automations/<id>` |
| AutomationRun | `GET /api/v1/automation-runs` | `GET /api/v1/automation-runs/<id>` | `POST /api/v1/automation-runs` | `PUT /api/v1/automation-runs/<id>` | `DELETE /api/v1/automation-runs/<id>` |
| AutomationStepLog | `GET /api/v1/automation-step-logs` | `GET /api/v1/automation-step-logs/<id>` | `POST /api/v1/automation-step-logs` | `PUT /api/v1/automation-step-logs/<id>` | `DELETE /api/v1/automation-step-logs/<id>` |
| AutomationGenerationLog | `GET /api/v1/automation-generation-logs` | `GET /api/v1/automation-generation-logs/<id>` | `POST /api/v1/automation-generation-logs` | `PUT /api/v1/automation-generation-logs/<id>` | `DELETE /api/v1/automation-generation-logs/<id>` |
| ExecutionLog | `GET /api/v1/execution-logs` | `GET /api/v1/execution-logs/<id>` | `POST /api/v1/execution-logs` | `PUT /api/v1/execution-logs/<id>` | `DELETE /api/v1/execution-logs/<id>` |
| Integration | `GET /api/v1/integrations` | `GET /api/v1/integrations/<id>` | `POST /api/v1/integrations` | `PUT /api/v1/integrations/<id>` | `DELETE /api/v1/integrations/<id>` |
| MessageFeedback | `GET /api/v1/message-feedback` | `GET /api/v1/message-feedback/<id>` | `POST /api/v1/message-feedback` | `PUT /api/v1/message-feedback/<id>` | `DELETE /api/v1/message-feedback/<id>` |
| AiSuggestion | `GET /api/v1/ai-suggestions` | `GET /api/v1/ai-suggestions/<id>` | `POST /api/v1/ai-suggestions` | `PUT /api/v1/ai-suggestions/<id>` | `DELETE /api/v1/ai-suggestions/<id>` |
| PageContext | `GET /api/v1/page-contexts` | `GET /api/v1/page-contexts/<id>` | `POST /api/v1/page-contexts` | `PUT /api/v1/page-contexts/<id>` | `DELETE /api/v1/page-contexts/<id>` |
| BrowserSession | `GET /api/v1/browser-sessions` | `GET /api/v1/browser-sessions/<id>` | `POST /api/v1/browser-sessions` | `PUT /api/v1/browser-sessions/<id>` | `DELETE /api/v1/browser-sessions/<id>` |
| PageAnalysisCache | `GET /api/v1/page-analysis-cache` | `GET /api/v1/page-analysis-cache/<id>` | `POST /api/v1/page-analysis-cache` | `PUT /api/v1/page-analysis-cache/<id>` | `DELETE /api/v1/page-analysis-cache/<id>` |
| UserDevice | `GET /api/v1/user-devices` | `GET /api/v1/user-devices/<id>` | `POST /api/v1/user-devices` | `PUT /api/v1/user-devices/<id>` | `DELETE /api/v1/user-devices/<id>` |
| UserWebhookConfig | `GET /api/v1/user-webhook-configs` | `GET /api/v1/user-webhook-configs/<id>` | `POST /api/v1/user-webhook-configs` | `PUT /api/v1/user-webhook-configs/<id>` | `DELETE /api/v1/user-webhook-configs/<id>` |
| IaMemory | `GET /api/v1/ia-memories` | `GET /api/v1/ia-memories/<id>` | `POST /api/v1/ia-memories` | `PUT /api/v1/ia-memories/<id>` | `DELETE /api/v1/ia-memories/<id>` |

## Arquitetura

O backend segue a arquitetura do professor com 4 camadas bem definidas:

```
HTTP Request → Route → Controller → Service → Model (db.Model) → Banco
```

- **Models**: Representam domínio + tabela, com métodos CRUD (`salvar`, `atualizar`, `deletar`, `listar_todos`, `buscar_por_id`, `to_dict`)
- **Services**: Um por caso de uso (criar/listar/buscar/atualizar/deletar), com validação de regras de negócio
- **Controllers**: Um por Model/recurso, recebem HTTP, chamam Services, devolvem JSON
- **Routes**: Centralizadas em `routes.py`, mapeiam URL + método HTTP → Controller

```
backend/
├── app/
│   ├── __init__.py         # create_app(), init_firebase()
│   ├── extensions.py       # db = SQLAlchemy()
│   ├── routes.py           # 85 rotas CRUD centralizadas
│   ├── models/             # 17 modelos SQLAlchemy com CRUD
│   ├── controllers/        # 17 controllers (um por Model)
│   └── services/           # 85 services (5 por entidade)
├── core/                   # Config, error handling
├── worker/                 # Temporal Worker
├── tests/                  # Testes automatizados
├── run.py                  # Entrypoint da API
├── run_catas.ps1           # Script de atalho
└── frontend/               # App Flutter (Dart)
```

## Testar

1. Com a API rodando, visite http://localhost:8000/health
2. Use o Swagger em `/` para explorar os endpoints
3. Para testes automatizados:

```bash
cd backend
.\venv\Scripts\activate
python -m pytest tests/ -v
```