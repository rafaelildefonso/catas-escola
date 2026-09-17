# CATAS (Context Aware Task Automation System)

## Equipe

- Rafael Ildefonso Furtado
- Lucas Salman Resende
- Henrique Santos Tavares
- Miguel Teixeira Valadao
- Lucas Nunes Araujo

Agente de Automação Inteligente baseado em Linguagem Natural que **executa ações** no mundo real através de uma interface de chat multiplataforma.

**Produção:** https://catas.app | **API:** https://catas-ai.onrender.com/api/v1

---

## Arquitetura

- **Client (Flutter):** Interface multiplataforma (Android, iOS, Web, Desktop)
- **Backend API (Flask):** Processa linguagem natural com IA multi-agente
- **Worker (FastAPI):** Executa automações em background

```
┌─────────────────────────────────────────────────────────────────┐
│                    FRONTEND (Flutter)                           │
│    ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│    │  Chat   │  │Automação│  │Dashboard│  │Configurações│      │
│    └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘        │
└─────────┼────────────┼────────────┼────────────┼───────────────┘
          │            │            │            │
          ▼            ▼            ▼            ▼
┌─────────────────────────────────────────────────────────────────┐
│                BACKEND API (Flask + Gunicorn)                   │
│    ┌───────────────────────────────────────────────────────┐   │
│    │              Route → Controller → Service → Model      │   │
│    └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                WORKER (FastAPI + uvicorn)                       │
│    ┌───────────────────────────────────────────────────────┐   │
│    │           AutomationRunner + Module Registry          │   │
│    └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Camada | Tecnologia | Versão |
|--------|-----------|--------|
| Frontend | Flutter (Dart) - Android, iOS, Web, Desktop | 3.10.8+ |
| Backend | Python 3.11+, Flask + SQLAlchemy | 3.0+ / 2.0+ |
| Worker | Python 3.11+, FastAPI + uvicorn | latest |
| AI | Groq (llama-3.1/3.3), Gemini 2.5, OpenAI | multi-provider |
| Database | PostgreSQL (Supabase) ou SQLite (dev) | - |
| Auth | Firebase Auth + JWT | - |
| Pagamentos | Stripe (Basic/Pro/Max) | - |
| Container | Docker + Docker Compose | Python 3.11-slim |
| Deploy | Render (Backend) + Vercel (Frontend) | - |
| Linter | Ruff | 0.3.5 |
| Testes | Pytest + pytest-asyncio | 8.1.1 |

---

## Funcionalidades Implementadas

### Autenticação
1. **Criar conta** — `POST /api/v1/auth/signup` → User + Profile
2. **Login/logout** — `POST /api/v1/auth/login` → User

### Chat
3. **Enviar mensagem com resposta de IA** — `POST /api/v1/chat/message` → AIService + Message
4. **Gerenciar sessões** — `GET/POST/PATCH/DELETE /api/v1/chat/sessions`
5. **Histórico de mensagens** — `GET /api/v1/chat/history/<session_id>`

### Automações
6. **Gerenciar automações** — `GET/POST/PUT/DELETE /api/v1/automations`
7. **Disparar automação** — `POST /api/v1/automations/trigger`

### Integrações
8. **Listar integrarões** — `GET/POST/PUT/DELETE /api/v1/integrations`
9. **OAuth Google** — Gmail, Calendar, Sheets, Drive

### Relatórios
10. **Dashboard** — `GET /api/v1/relatorios/dashboard`
11. **Relatório automações** — `GET /api/v1/relatorios/automacoes`
12. **Relatório chat** — `GET /api/v1/relatorios/chat`
13. **Busca de mensagens** — `GET /api/v1/relatorios/mensagens/busca`

### Perfil
14. **Atualizar perfil** — `PUT /api/v1/profiles/<id>`

---

## Quick Start

### Pré-requisitos
- Python 3.11+
- Conta Supabase + credenciais de API
- Firebase Auth (para autenticação)
- Stripe (para pagamentos)

### 1. Configurar .env

```bash
cd backend
cp .env.example .env
# Edite com suas credenciais
```

### 2. Rodar a API

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python run.py
```

API: http://localhost:8000 | Health: http://localhost:8000/health

### 3. Rodar o Worker (opcional, para automações)

```bash
cd backend
venv\Scripts\activate
python -m worker.server
```

Worker: http://localhost:8001

### 4. Usando Docker

```bash
cd backend
docker-compose up -d
```

Serviços:
- `catas_server`: API Flask (port 8000)
- `catas_worker`: FastAPI Worker (port 8001)

### 5. Rodar o Flutter App

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 52159
```

---

## Estrutura do Projeto

```
CATAS - Escola/
├── backend/                 # API Flask + Worker FastAPI
│   ├── application.py       # create_app(), init_firebase()
│   ├── routes.py            # ~112 endpoints
│   ├── models/              # 18 models SQLAlchemy
│   ├── controllers/         # 24 controllers
│   ├── services/            # 24 pastas, ~120 arquivos
│   ├── repositories/        # 8 repositories
│   ├── core/                # Config, security, OAuth
│   ├── worker/              # FastAPI worker
│   ├── tests/               # 11 arquivos de teste
│   ├── migrations/          # 20+ migrations SQL
│   ├── docker-compose.yml   # Docker config
│   └── Dockerfile           # API container
├── frontend/                # App Flutter (Dart)
│   ├── lib/
│   │   ├── components/      # 44 widgets
│   │   ├── screens/         # 26 telas
│   │   ├── providers/       # 15 providers
│   │   ├── models/          # 6 modelos
│   │   └── data/            # 9 repositories
│   └── test/                # Testes Flutter
├── docs/                    # Documentação Mintlify
├── README.md                # Este arquivo
├── AGENTS.md                # Guia de arquitetura
├── arquitetura.md           # Análise estratégica
├── PROJECT_CONTEXT.md       # Contexto completo
├── TASKS.md                 # Roadmap SaaS
└── RUN_CATAS.md             # Instruções de execução
```

---

## Models (18 Entidades)

| # | Model | Tabela | Descrição |
|---|-------|--------|-----------|
| 1 | **User** | `users` | Usuários e credenciais |
| 2 | **Profile** | `profiles` | Perfil, assinatura, cotas |
| 3 | **ChatSession** | `chat_sessions` | Sessões de chat |
| 4 | **Message** | `messages` | Mensagens do chat |
| 5 | **Automation** | `automations` | Definições de automação |
| 6 | **AutomationRun** | `automation_runs` | Execuções de automação |
| 7 | **AutomationStepLog** | `automation_step_logs` | Logs por passo |
| 8 | **AutomationGenerationLog** | `automation_generation_logs` | Auditoria do planner |
| 9 | **ExecutionLog** | `execution_logs` | Logs legados |
| 10 | **Integration** | `integrations` | Tokens OAuth |
| 11 | **MessageFeedback** | `message_feedback` | Feedback mensagens |
| 12 | **AiSuggestion** | `ai_suggestions` | Sugestões de IA |
| 13 | **PageContext** | `page_contexts` | Contexto de página |
| 14 | **BrowserSession** | `browser_sessions` | Sessões navegador |
| 15 | **PageAnalysisCache** | `page_analysis_cache` | Cache análises |
| 16 | **UserDevice** | `user_devices` | Tokens FCM |
| 17 | **UserWebhookConfig** | `user_webhook_configs` | Config webhooks |
| 18 | **IaMemory** | `ia_memory` | Memória semântica (RAG) |

---

## Rotas da API (~112 Rotas)

### Padrão CRUD (5 endpoints por entidade)

| Método | Endpoint | Função |
|--------|----------|--------|
| GET | `/api/v1/<recursos>` | Listar todos |
| GET | `/api/v1/<recursos>/<id>` | Buscar por ID |
| POST | `/api/v1/<recursos>` | Criar |
| PUT | `/api/v1/<recursos>/<id>` | Atualizar |
| DELETE | `/api/v1/<recursos>/<id>` | Deletar |

### Endpoints Especiais

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/api/v1/auth/signup` | Criar conta |
| POST | `/api/v1/auth/login` | Login |
| POST | `/api/v1/chat/message` | Enviar mensagem |
| GET | `/api/v1/chat/history/<session_id>` | Histórico |
| POST | `/api/v1/automations/trigger` | Disparar automação |
| GET | `/api/v1/relatorios/dashboard` | Dashboard |
| GET | `/api/v1/relatorios/automacoes` | Relatório automações |
| GET | `/api/v1/relatorios/chat` | Relatório chat |
| GET | `/api/v1/relatorios/mensagens/busca` | Busca mensagens |

---

## Arquitetura Backend

O backend segue a arquitetura com camadas bem definidas:

```
HTTP Request → Route → Controller → Service → Repository → Procedure (PostgreSQL)
                                 └─→ Model (db.Model) → CRUD básico
```

| Camada | Responsabilidade |
|--------|-----------------|
| **Route** | Mapeamento URL → endpoint |
| **Controller** | HTTP request/response |
| **Service** | Lógica de negócio, validação |
| **Repository** | Consultas complexas, procedures |
| **Model** | Schema + CRUD básico |

---

## Funcionalidades Avançadas (Relatórios)

| Funcionalidade | Endpoint | Descrição |
|----------------|----------|-----------|
| **Dashboard** | `GET /api/v1/relatorios/dashboard` | Estatísticas gerais |
| **Relatório Automações** | `GET /api/v1/relatorios/automacoes` | Execuções filtradas |
| **Relatório Chat** | `GET /api/v1/relatorios/chat` | Sessões e mensagens |
| **Busca Mensagens** | `GET /api/v1/relatorios/mensagens/busca` | Busca por termo |

### Procedures PostgreSQL

| Procedure | Função |
|-----------|--------|
| `fn_dashboard_estatisticas` | Agregação multi-tabela |
| `fn_relatorio_automacoes` | Filtros dinâmicos e paginação |
| `fn_relatorio_chat` | JOIN sessões × mensagens |
| `fn_buscar_mensagens` | Busca ILIKE com paginação |

---

## Testes

### Backend

```bash
cd backend
python -m pytest tests/ -v
python -m pytest tests/test_all_entities.py -v
python -m pytest tests/test_auth_user.py -v
python -m pytest tests/test_chat_flow.py -v
```

### Frontend

```bash
cd frontend
flutter test
```

---

## Documentação

- [Documentação Completa](./docs/) - Site de documentação Mintlify
- [Guia de Arquitetura](./AGENTS.md) - Para agentes de IA
- [Análise Estratégica](./arquitetura.md) - Build-Time vs Run-Time
- [Contexto do Projeto](./PROJECT_CONTEXT.md) - Visão completa
- [Roadmap SaaS](./TASKS.md) - Tarefas e roadmap
- [Instruções de Execução](./RUN_CATAS.md) - Como rodar

---

## Deploy

### Produção

| Serviço | URL | Stack |
|---------|-----|-------|
| **App** | https://catas.app | Flutter Web |
| **API** | https://catas-ai.onrender.com/api/v1 | Flask + Gunicorn |
| **Worker** | https://catas-ai.onrender.com | FastAPI |
| **Database** | Supabase | PostgreSQL |
| **Auth** | Firebase | Auth |
| **Pagamentos** | Stripe | Billing |

### CI/CD

- **Lint:** Ruff (Python)
- **Testes:** Pytest
- **Deploy Backend:** Render Deploy Hooks
- **Deploy Frontend:** Vercel

---

## Tecnologias

### Backend
- Flask 3.0+ (API)
- SQLAlchemy 2.0+ (ORM)
- FastAPI (Worker)
- Gunicorn (Server)
- PostgreSQL/SQLite (Database)
- Firebase Auth (Autenticação)
- Groq/Gemini/OpenAI (IA)
- Stripe (Pagamentos)
- Docker (Containerização)

### Frontend
- Flutter 3.10.8+ (Framework)
- Provider (State Management)
- GoRouter (Navegação)
- Dio (HTTP)
- Material Design 3 (UI)

### Infra
- Render (Deploy)
- Vercel (Frontend)
- Supabase (Database + Auth)
- Firebase (Auth + Push)
- Stripe (Pagamentos)

---

## Licença

Projeto acadêmico - CATAS 2026

---

**Última Atualização:** Setembro de 2026
