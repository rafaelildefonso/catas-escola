# CATAS - Contexto Completo do Projeto

> **Documentação por Módulo:**
> - 📱 [App Flutter](./frontend/) - Frontend multiplataforma
> - 🖥️ [Backend API](./backend/) - API Flask + Worker FastAPI
> - 🐳 [Docker](./backend/docker-compose.yml) - Containerização

## 1. Visão Geral

**Nome:** CATAS (Context Aware Task Automation System)  
**Tipo:** Plataforma SaaS de Automação Inteligente  
**Stack:** Flask (Backend) + FastAPI (Worker) + Flutter (Frontend)  
**Deploy:** https://catas-ai.vercel.app | API: https://catas-ai.onrender.com/api/v1

### Objetivo

Demonstrar a aplicação de **Modelos de Linguagem (LLMs)** como o "Cérebro" de sistemas de automação. O CATAS interpreta comandos em linguagem natural, planeja execuções multi-step e aciona APIs externas com resiliência.

---

## 2. Tech Stack

| Camada | Tecnologia | Versão | Função |
|--------|-----------|--------|--------|
| **Frontend** | Flutter (Dart) | 3.10.8+ | App multiplataforma (Android/iOS/Web/Desktop) |
| **Backend API** | Flask + SQLAlchemy | 3.0+ / 2.0+ | API REST, autenticação, pipeline de IA |
| **Worker** | FastAPI + uvicorn | latest | Execução de automações em background |
| **Database** | PostgreSQL (Supabase) | - | Dados em produção |
| **Database Dev** | SQLite | - | Desenvolvimento e testes |
| **Auth** | Firebase Auth + JWT | - | Autenticação de usuários |
| **IA** | Groq, Gemini, OpenAI | - | Pipeline multi-agente |
| **Pagamentos** | Stripe | - | Billing (Basic/Pro/Max) |
| **Container** | Docker | Python 3.11-slim | Containerização |
| **Deploy** | Render (Backend) + Vercel (Frontend) | - | Hospedagem |

---

## 3. Arquitetura

### 3.1 Diagrama de Componentes

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
│    │              Route Layer (routes.py)                  │   │
│    └───────────────────────────────────────────────────────┘   │
│                            │                                    │
│    ┌───────────────────────────────────────────────────────┐   │
│    │           Controller Layer (24 controllers)           │   │
│    └───────────────────────────────────────────────────────┘   │
│                            │                                    │
│    ┌───────────────────────────────────────────────────────┐   │
│    │          Service Layer (24 pastas, ~120 arquivos)     │   │
│    └───────────────────────────────────────────────────────┘   │
│                            │                                    │
│    ┌───────────────────────────────────────────────────────┐   │
│    │          Repository Layer (8 repositories)            │   │
│    └───────────────────────────────────────────────────────┘   │
│                            │                                    │
│    ┌───────────────────────────────────────────────────────┐   │
│    │          Model Layer (18 models SQLAlchemy)           │   │
│    └───────────────────────────────────────────────────────┘   │
│                            │                                    │
│    ┌───────────────────────────────────────────────────────┐   │
│    │         PostgreSQL (Supabase) / SQLite (dev)          │   │
│    └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ POST /api/v1/automations/trigger
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                WORKER (FastAPI + uvicorn)                       │
│    ┌───────────────────────────────────────────────────────┐   │
│    │           AutomationRunner (runner.py)                │   │
│    └───────────────────────────────────────────────────────┘   │
│                            │                                    │
│    ┌───────────────────────────────────────────────────────┐   │
│    │           Module Registry (modules/)                  │   │
│    │    ┌─────────┐  ┌─────────┐  ┌─────────┐            │   │
│    │    │  Gmail  │  │Calendar │  │ Sheets  │            │   │
│    │    └─────────┘  └─────────┘  └─────────┘            │   │
│    └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Princípios de Arquitetura

1. **Mobile-First & Cross-Platform:** Flutter para Android, iOS, Web e Desktop
2. **Backend "Maestro":** IA e planejamento no Backend Python
3. **Execução Assíncrona:** Worker FastAPI para automações em background
4. **Separação de Responsabilidades:** API (dados) separada do Worker (execução)

---

## 4. Pipeline de IA (Multi-Agente)

O CATAS utiliza uma arquitetura de pipeline multi-agente:

```
Mensagem do Usuário
    ↓
┌─────────────────────────────────────┐
│  AGENT_INTENT_CLASSIFIER            │
│  (Groq openai/gpt-oss-20b)       │
│  Classifica: CHAT ou ACTION         │
└─────────────────────────────────────┘
    ↓ (se ACTION)
┌─────────────────────────────────────┐
│  AGENT_ENTITY_EXTRACTOR             │
│  Extrai: nomes, datas, emails       │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  AGENT_INTERPRETER                  │
│  Interpreta: ideia do usuário       │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  AGENT_SELECTOR                     │
│  Seleciona: módulos disponíveis     │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  AGENT_DEVELOPER                    │
│  Gera: JSON do plano de automação   │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  AutomationValidator                │
│  Valida: module_ids, params, tipos  │
└─────────────────────────────────────┘
    ↓
Plano Válido → Worker para Execução
```

### Configuração de Modelos

| Modelo | Provider | Uso |
|--------|----------|-----|
| `MODEL_TIER_BASIC` | Groq openai/gpt-oss-20b | Chat básico |
| `MODEL_TIER_PRO` | Gemini 2.5 Flash | Chat intermediário |
| `MODEL_TIER_MAX` | Gemini 2.5 Pro | Chat avançado |

---

## 5. Estrutura do Backend

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
├── services/              # 24 pastas, ~120 arquivos
│   ├── auth/
│   ├── user/
│   ├── profile/
│   ├── chat/
│   ├── automacao/
│   ├── ia/
│   ├── integration/
│   ├── feedback/
│   ├── relatorio/
│   └── ... (mais 15 pastas)
├── repositories/          # 8 repositories
├── core/                  # Config, security, OAuth
├── worker/                # FastAPI worker
│   ├── server.py          # FastAPI app
│   ├── runner.py          # AutomationRunner
│   ├── modules/           # Módulos de integração
│   └── utils/             # Utilities
├── tests/                 # 11 arquivos de teste
├── migrations/            # 20+ migrations SQL
├── docker-compose.yml     # Docker config
├── Dockerfile             # API container
└── Dockerfile.worker      # Worker container
```

---

## 6. Estrutura do Frontend

```
frontend/
├── lib/
│   ├── main.dart          # Entry point
│   ├── components/        # 44 widgets reutilizáveis
│   │   ├── ai_components/ # 22 componentes IA
│   │   ├── dashboard/     # Metric cards, charts
│   │   └── ... (widgets gerais)
│   ├── core/              # Config, router, theme
│   ├── data/              # Repositories e services
│   ├── l10n/              # Internacionalização (PT/EN)
│   ├── models/            # 6 modelos Dart
│   ├── providers/         # 15 providers (state management)
│   ├── screens/           # 26 telas
│   └── services/          # Token holder
├── test/                  # Testes Flutter
└── pubspec.yaml           # Dependências
```

---

## 7. Banco de Dados

### 7.1 Entidades Principais (18 models)

| Model | Tabela | Descrição |
|-------|--------|-----------|
| **User** | `users` | Usuários e credenciais |
| **Profile** | `profiles` | Perfil, assinatura, cotas |
| **ChatSession** | `chat_sessions` | Sessões de chat |
| **Message** | `messages` | Mensagens do chat |
| **Automation** | `automations` | Definições de automação |
| **AutomationRun** | `automation_runs` | Execuções de automação |
| **AutomationStepLog** | `automation_step_logs` | Logs por passo |
| **AutomationGenerationLog** | `automation_generation_logs` | Auditoria do planner |
| **ExecutionLog** | `execution_logs` | Logs legados |
| **Integration** | `integrations` | Tokens OAuth |
| **MessageFeedback** | `message_feedback` | Feedback mensagens |
| **AiSuggestion** | `ai_suggestions` | Sugestões de IA |
| **PageContext** | `page_contexts` | Contexto de página |
| **BrowserSession** | `browser_sessions` | Sessões navegador |
| **PageAnalysisCache** | `page_analysis_cache` | Cache análises |
| **UserDevice** | `user_devices` | Tokens FCM |
| **UserWebhookConfig** | `user_webhook_configs` | Config webhooks |
| **IaMemory** | `ia_memory` | Memória semântica (RAG) |

### 7.2 Procedures PostgreSQL

| Procedure | Função |
|-----------|--------|
| `fn_dashboard_estatisticas` | Estatísticas do dashboard |
| `fn_relatorio_automacoes` | Relatório de automações |
| `fn_relatorio_chat` | Relatório de conversas |
| `fn_buscar_mensagens` | Busca de mensagens |
| `match_ia_memory` | Busca semântica (pgvector) |

---

## 8. API Reference

### 8.1 Endpoints Principais

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/api/v1/auth/signup` | Criar conta |
| POST | `/api/v1/auth/login` | Login |
| POST | `/api/v1/chat/message` | Enviar mensagem |
| GET | `/api/v1/chat/sessions` | Listar sessões |
| GET | `/api/v1/chat/history/<session_id>` | Histórico |
| GET | `/api/v1/automations` | Listar automações |
| POST | `/api/v1/automations` | Criar automação |
| POST | `/api/v1/automations/trigger` | Disparar automação |
| GET | `/api/v1/relatorios/dashboard` | Dashboard |
| GET | `/api/v1/relatorios/automacoes` | Relatório automações |
| GET | `/api/v1/relatorios/chat` | Relatório chat |

### 8.2 Padrão CRUD

Cada entidade possui 5 endpoints REST:

| Método | Endpoint | Função |
|--------|----------|--------|
| GET | `/api/v1/<recursos>` | Listar todos |
| GET | `/api/v1/<recursos>/<id>` | Buscar por ID |
| POST | `/api/v1/<recursos>` | Criar |
| PUT | `/api/v1/<recursos>/<id>` | Atualizar |
| DELETE | `/api/v1/<recursos>/<id>` | Deletar |

---

## 9. Planos e Assinaturas

| Recurso | Free | Pro | Max |
|---------|------|-----|-----|
| **Créditos** | 50/mês | Ilimitado* | Ilimitado* |
| **Modelo** | Groq openai/gpt-oss-20b | Gemini 2.5 Flash | Gemini 2.5 Pro |
| **Histórico** | 30 dias | Ilimitado | Ilimitado |
| **Automações** | 1 step | Multi-step | Multi-step + Agendamento |
| **Integrações** | Básicas | Todas | Todas + Premium |

*Sujeito a Fair Use Policy. Créditos: 2000 tokens = 1 crédito.

---

## 10. Variáveis de Ambiente

### Backend (.env)

```env
# === SUPABASE ===
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=

# === DATABASE ===
DATABASE_URL=

# === AUTH ===
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# === FIREBASE ===
FIREBASE_ADMIN_SDK_JSON_PATH=

# === IA ===
OPENAI_API_KEY=
GOOGLE_API_KEY=
GROQ_API_KEY=

# === MODELS ===
MODEL_TIER_BASIC=groq|openai/gpt-oss-20b|https://api.groq.com/openai|GROQ_API_KEY
MODEL_TIER_PRO=gemini|gemini-2.5-flash|https://generativelanguage.googleapis.com|GOOGLE_API_KEY
MODEL_TIER_MAX=gemini|gemini-2.5-pro|https://generativelanguage.googleapis.com|GOOGLE_API_KEY

# === STRIPE ===
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
BASIC_PLAN_ID=
PRO_PLAN_ID=
MAX_PLAN_ID=

# === APP ===
APP_DEEP_LINK_SCHEME=catas
ENCRYPTION_KEY=
ENVIRONMENT=development

# === WORKER ===
WORKER_URL=http://catas_worker:8001
```

### Frontend (.env)

```env
# === SUPABASE ===
SUPABASE_URL=
SUPABASE_ANON_KEY=

# === API ===
API_BASE_URL=http://localhost:8000

# === OAUTH ===
WEB_CLIENT_ID=
ANDROID_CLIENT_ID=
IOS_CLIENT_ID=

# === CLOUDINARY ===
CLOUDINARY_CLOUD_NAME=
```

---

## 11. Quick Start

### 1. Backend API

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python run.py
```

API: http://localhost:8000

### 2. Worker (opcional)

```bash
cd backend
venv\Scripts\activate
python -m worker.server
```

Worker: http://localhost:8001

### 3. Docker

```bash
cd backend
docker-compose up -d
```

### 4. Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

---

## 12. Testes

```bash
cd backend
python -m pytest tests/ -v
python -m pytest tests/test_all_entities.py -v
python -m pytest tests/test_auth_user.py -v
```

---

## 13. Deploy

### Produção

- **Backend:** Render (https://catas-ai.onrender.com)
- **Frontend:** Vercel (https://catas-ai.vercel.app)
- **Database:** Supabase (PostgreSQL)
- **Auth:** Firebase Auth
- **Pagamentos:** Stripe

### CI/CD

- **Lint:** Ruff (Python)
- **Testes:** Pytest
- **Deploy:** Render Deploy Hooks + Vercel

---

## 14. Roadmap

### Concluído ✅
- Backend Flask com pipeline de IA
- Worker FastAPI para automações
- Frontend Flutter multiplataforma
- Sistema de autenticação (Google/Email)
- Sistema de créditos e billing
- 18 models com CRUD completo
- 112 endpoints REST
- Docker containerização

### Em Progresso 🔄
- Expansão de integrações (Meta Ads, Notion, Slack)
- Testes E2E
- Modo demo
- Push notifications

### Pendente ⏳
- RevenueCat (assinaturas mobile)
- Landing page
- Publicação nas lojas (App Store, Play Store)

---

**Última Atualização:** Setembro de 2026  
**Equipe:** Rafael, Lucas, Henrique, Miguel, Lucas
