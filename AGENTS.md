# CATAS — Architecture Guide

## Architecture (`backend/`)

```
backend/
├── application.py         # create_app(), init_firebase(), error handlers
├── routes.py              # Centralized route registration (~112 routes)
├── extensions.py          # db = SQLAlchemy()
├── run.py                 # Entry point: creates app, tables, Firebase, runs Flask
├── models/                # 18 SQLAlchemy models with CRUD methods
│   ├── user.py
│   ├── profile.py
│   ├── chat_session.py
│   ├── message.py
│   ├── automation.py
│   ├── automation_run.py
│   ├── automation_step_log.py
│   ├── automation_generation_log.py
│   ├── execution_log.py
│   ├── integration.py
│   ├── message_feedback.py
│   ├── ai_suggestion.py
│   ├── page_context.py
│   ├── browser_session.py
│   ├── page_analysis_cache.py
│   ├── user_device.py
│   ├── user_webhook_config.py
│   └── ia_memory.py
├── controllers/           # 24 controllers (CRUD + Chat/Chatbot/Feedback/Relatorio)
├── services/              # Business logic (one service per use case)
│   ├── auth/              # 3 services (criar_conta, autenticar, obter)
│   ├── user/              # 5 services (CRUD padrão)
│   ├── profile/           # 7 services (CRUD + quota + credit)
│   ├── chat/              # 13 services (sessões + mensagens + onboarding)
│   ├── automacao/         # 6 services (runner + pipeline + registry)
│   ├── ia/                # 8 services (AI pipeline + providers)
│   ├── integration/       # 6 services (CRUD + google_auth)
│   ├── feedback/          # 2 services (registrar + resumo)
│   ├── relatorio/         # 4 services (chat + automações + dashboard)
│   └── ... (mais 15 pastas CRUD)
├── repositories/          # Complex queries (reports, PostgreSQL procedures)
│   ├── base.py
│   ├── automacao_repository.py
│   ├── chat_repository.py
│   ├── dashboard_repository.py
│   ├── feedbacks_repository.py
│   ├── integracoes_repository.py
│   ├── sessoes_chat_repository.py
│   └── __init__.py
├── core/                  # Config, security, OAuth
│   ├── config.py          # Settings com todas as env vars
│   ├── security.py        # JWT auth
│   ├── crypto.py          # AES-256 para tokens OAuth
│   ├── errors.py          # sanitize_error()
│   └── oauth_token_service.py
├── worker/                # FastAPI worker (automations)
│   ├── server.py          # FastAPI app (port 8001)
│   ├── runner.py          # AutomationRunner
│   ├── modules/           # Módulos de integração
│   │   ├── registry.py
│   │   ├── ai_modules.py
│   │   ├── flow_modules.py
│   │   ├── http_modules.py
│   │   ├── gmail_modules.py
│   │   ├── google_calendar_modules.py
│   │   ├── google_drive_modules.py
│   │   └── google_sheets_modules.py
│   └── utils/             # VariableResolver, google_auth, decorators
├── tests/                 # 11 test files
├── migrations/            # 20+ SQL migrations + procedures
├── docker-compose.yml     # 2 services: server + worker
├── Dockerfile             # Python 3.11-slim, gunicorn, 4 workers
└── Dockerfile.worker      # Python 3.11-slim, worker/entrypoint.py
```

## Layer Rules

| Layer | Responsibility | CRUD? |
|-------|---------------|-------|
| **Model** | Data schema + `salvar()`, `atualizar()`, `deletar()`, `listar_todos()`, `buscar_por_id()`, `to_dict()` | Yes |
| **Service** | Business logic, validation, filtering | Yes |
| **Controller** | HTTP request/response handling | No direct DB |
| **Repository** | Complex queries, PostgreSQL procedures, filters | Read-only |
| **Route** | URL → endpoint mapping | No logic |

## CRUD Flow

```
HTTP POST /api/v1/profiles
  → routes.py → ProfileController.criar()
    → CriarProfileService.executar(dados)
      → Profile(**dados) → profile.salvar()
    → return jsonify(model.to_dict()), 201
```

## Adding a New Entity

1. Create `models/seu_modelo.py` with `salvar/atualizar/deletar/listar_todos/buscar_por_id/to_dict`
2. Create `controllers/seu_modelo_controller.py` with CRUD methods
3. Create `services/seu_modelo/criar_seu_modelo_service.py`
4. Register routes in `routes.py`
5. Add to `models/__init__.py`

## Service Pattern

Each service follows this pattern:

```python
class CriarXxxService:
    @staticmethod
    def executar(dados):
        # 1. Validate input
        # 2. Check business rules
        # 3. Create model instance
        # 4. Call model.salvar()
        # 5. Return result
```

## Repository Pattern

Repositories handle complex queries:

```python
class XxxRepository:
    @staticmethod
    def listar_filtrados(user_id, filtros):
        # Complex queries with JOINs, filters, pagination
        # Uses PostgreSQL procedures in production
        # Fallback to SQL inline in SQLite (dev/test)
```

## Worker Architecture

The FastAPI worker executes automations:

```
POST /execute
  → AutomationRunner.processar()
    → parse JSON plan
    → VariableResolver.resolve(params, context)
    → Execute modules sequentially
    → Log each step
    → Return results
```

### Module Registry

| Module | Description | Integration |
|--------|-------------|-------------|
| `gmail.send_email` | Send email | Google OAuth |
| `gmail.create_draft` | Create draft | Google OAuth |
| `google_calendar.create_event` | Create event | Google OAuth |
| `google_calendar.check_availability` | Check availability | Google OAuth |
| `google_sheets.append_row` | Append row | Google OAuth |
| `google_sheets.read_range` | Read range | Google OAuth |
| `flow.wait` | Wait duration | None |
| `flow.condition` | Conditional | None |
| `flow.loop` | Loop | None |

### Variable Resolver

Syntax: `{{step_id.campo}}`

Examples:
- `{{trigger.email}}` → Email from trigger event
- `{{step_1.response}}` → Response from step 1
- `{{user.email}}` → User's email

## Test Commands

```bash
cd backend
python -m pytest tests/ -v
python -m pytest tests/test_all_entities.py -v
python -m pytest tests/test_auth_user.py -v
python -m pytest tests/test_chat_flow.py -v
python -m pytest tests/test_ai_service.py -v
python -m pytest tests/test_worker_runner.py -v
```

## Lint Commands

```bash
cd backend
ruff check .
ruff format .
```

## Run

```bash
cd backend
python run.py
```

## Run with Docker

```bash
cd backend
docker-compose up -d
```

## Environment Variables

See `.env.example` for all required variables:

- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`
- `DATABASE_URL` (PostgreSQL or SQLite)
- `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`
- `FIREBASE_ADMIN_SDK_JSON_PATH`
- `OPENAI_API_KEY`, `GOOGLE_API_KEY`, `GROQ_API_KEY`
- `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`
- `WORKER_URL=http://catas_worker:8001`

## Architecture Diagram

```
HTTP Request
    ↓
Route (routes.py)
    ↓
Controller (24 controllers)
    ↓
Service (24 folders, ~120 files)
    ↓
Repository (8 repositories)
    ↓
Model (18 models)
    ↓
PostgreSQL/SQLite
```

## Key Patterns

1. **Service Layer:** One service per use case (criar, listar, buscar, atualizar, deletar)
2. **Repository Layer:** Complex queries encapsulated in repositories
3. **Controller Layer:** HTTP handling only, no business logic
4. **Model Layer:** Schema + basic CRUD methods
5. **Worker Isolation:** Automations run in separate FastAPI process

## Database

- **Production:** PostgreSQL via Supabase
- **Development/Testing:** SQLite
- **Migrations:** SQL files in `backend/migrations/`
- **Procedures:** PostgreSQL functions for complex queries
- **RLS:** Row Level Security on all tables

---

**Last Updated:** September 2026
