# Estrutura do Backend

O backend do CATAS e composto por **dois servicos** em Python:

| Componente | Tecnologia | Funcao |
|---|---|---|
| **API Server** | Flask | HTTP API, autenticacao, orquestracao IA |
| **Worker** | FastAPI | Execucao de automacoes (assincrono) |

Ambos compartilham o mesmo codigo base (`core/`, `models/`, `repositories/`, `services/`).

---

## Estrutura de Diretorios

```
backend/
├── application.py         # create_app(), init_firebase()
├── routes.py              # Rotas centralizadas (~112 endpoints)
├── extensions.py          # db = SQLAlchemy()
├── run.py                 # Entry point da API
├── models/                # 18 models SQLAlchemy
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
├── controllers/           # 24 controllers
│   ├── auth_controller.py
│   ├── user_controller.py
│   ├── profile_controller.py
│   ├── chat_controller.py
│   ├── chatbot_controller.py
│   ├── automation_controller.py
│   ├── integration_controller.py
│   ├── relatorio_controller.py
│   └── ... (mais 16 controllers)
├── services/              # 24 pastas, ~120 arquivos
│   ├── auth/              # 3 services (criar_conta, autenticar, obter)
│   ├── user/              # 5 services (CRUD padrao)
│   ├── profile/           # 7 services (CRUD + quota + credit)
│   ├── chat/              # 13 services (sessoes + mensagens + onboarding)
│   ├── automacao/         # 6 services (runner + pipeline + registry)
│   ├── ia/                # 8 services (AI pipeline + providers)
│   ├── integration/       # 6 services (CRUD + google_auth)
│   ├── feedback/          # 2 services (registrar + resumo)
│   ├── relatorio/         # 4 services (chat + automacoes + dashboard)
│   └── ... (mais 15 pastas CRUD)
├── repositories/          # 8 repositories
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
├── worker/                # FastAPI worker
│   ├── server.py          # FastAPI app (port 8001)
│   ├── runner.py          # AutomationRunner
│   ├── modules/           # Modulos de integracao
│   │   ├── registry.py
│   │   ├── ai_modules.py
│   │   ├── flow_modules.py
│   │   ├── http_modules.py
│   │   ├── gmail_modules.py
│   │   ├── google_calendar_modules.py
│   │   ├── google_drive_modules.py
│   │   └── google_sheets_modules.py
│   └── utils/             # VariableResolver, google_auth, decorators
├── tests/                 # 11 arquivos de teste
├── migrations/            # 20+ migrations SQL
├── docker-compose.yml     # 2 services: server + worker
├── Dockerfile             # Python 3.11-slim, gunicorn, 4 workers
└── Dockerfile.worker      # Python 3.11-slim, worker/entrypoint.py
```

---

## Fluxo Principal: Chat

1. **Frontend** envia `POST /api/v1/chat/message` com `Authorization: Bearer <token>`.
2. **Backend (AIService)**:
   - **Classificador**: Detecta se e conversa ou intencao de automacao.
   - **Entity Extractor**: Extrai parametros (data, hora, email, etc).
   - **Payload Builder**: Monta plano de automacao.
   - **Worker**: Envia o plano para o Worker via HTTP (`/execute`).
   - **Creditos**: Custo em tokens e debitado do perfil (2k tokens = 1 credito).
3. **Worker**: Executa o plano (modulos como Google Calendar, Gmail, etc).
4. **Persistencia**: Resultados salvos via SQLAlchemy.

---

## Layer Rules

| Layer | Responsibility | CRUD? |
|-------|---------------|-------|
| **Model** | Data schema + `salvar()`, `atualizar()`, `deletar()`, `listar_todos()`, `buscar_por_id()`, `to_dict()` | Yes |
| **Service** | Business logic, validation, filtering | Yes |
| **Controller** | HTTP request/response handling | No direct DB |
| **Repository** | Complex queries, PostgreSQL procedures, filters | Read-only |
| **Route** | URL → endpoint mapping | No logic |

---

## CRUD Flow

```
HTTP POST /api/v1/profiles
  → routes.py → ProfileController.criar()
    → CriarProfileService.executar(dados)
      → Profile(**dados) → profile.salvar()
    → return jsonify(model.to_dict()), 201
```

---

## Repositories

Cada repository encapsula queries complexas:

| Arquivo | Funcao Principal |
|---|---|
| `automacao_repository.py` | Consultas de automacoes |
| `chat_repository.py` | Consultas de chat |
| `dashboard_repository.py` | Estatisticas dashboard |
| `feedbacks_repository.py` | Consultas de feedbacks |
| `integracoes_repository.py` | Consultas de integracoes |
| `sessoes_chat_repository.py` | Consultas de sessoes |

---

## Seguranca

- **get_current_user**: Valida JWT via Firebase Auth.
- **login_required**: Decorator que bloqueia rotas nao autenticadas.
- **RLS**: Row Level Security em todas as tabelas do Supabase.
- **Encryption**: AES-256 para tokens OAuth (`crypto.py`).

---

## Configuracao

Veja [variaveis de ambiente](../comecando/variaveis-ambiente.md).

---

## Como Rodar

```powershell
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python run.py
```

API disponivel em `http://127.0.0.1:8000`.

---

## Como Rodar com Docker

```powershell
cd backend
docker-compose up -d
```

Servicos:
- `catas_server`: API Flask (port 8000)
- `catas_worker`: FastAPI Worker (port 8001)

---

## Documentacao Relacionada

- [Pipeline de IA](./ia-pipeline.md) - Como funciona o pipeline de IA
- [API Reference](./api-referencia.md) - Todos os endpoints
- [Banco de Dados](../arquitetura/banco-dados.md) - Schema e tabelas
