# CATAS Backend API

Backend Flask do CATAS - Sistema de Automação de Tarefas com IA usando Temporal.io.

# CATAS Backend API

Backend Flask do CATAS - Sistema de Automação de Tarefas com IA usando Temporal.io.

## 🚀 Funcionalidades

- ✅ API REST com Flask
- ✅ Arquitetura CRUD (Model → Service → Controller → Route)
- ✅ 18 Models com CRUD completo (listadas abaixo)
- ✅ 90 endpoints REST (5 por entidade)
- ✅ **Relatórios além do CRUD básico** via Repository + procedures PostgreSQL (dashboard, automações, conversas, busca de mensagens)
- ✅ Autenticação via Firebase Auth (Bearer Token)
- ✅ Pipeline de IA multi-agente (Intent → Entities → Action)
- ✅ Orquestração de automações com Temporal.io
- ✅ Integrações: Google Calendar, Gmail, Google Sheets
- ✅ Sistema de créditos por uso de tokens
- ✅ Notificações push via Firebase
- ✅ Webhooks para Stripe (assinaturas)

## 🧱 Models e Rotas CRUD

Cada Model em `app/models/` herda de `db.Model` e implementa os métodos `salvar()`, `atualizar()`, `deletar()`, `listar_todos()`, `buscar_por_id()` e `to_dict()`.

| # | Model | Controller | Services (5) | Rotas CRUD |
|---|-------|-----------|-------------|------------|
| 1 | **User** | `user_controller.py` | `services/user/` | `GET/POST /api/v1/users`, `GET/PUT/DELETE /api/v1/users/<id>` |
| 2 | **Profile** | `profile_controller.py` | `services/profile/` | `GET/POST /api/v1/profiles`, `GET/PUT/DELETE /api/v1/profiles/<id>` |
| 2 | **ChatSession** | `chat_session_controller.py` | `services/chat_session/` | `GET/POST /api/v1/chat-sessions`, `GET/PUT/DELETE /api/v1/chat-sessions/<id>` |
| 3 | **Message** | `message_controller.py` | `services/message/` | `GET/POST /api/v1/messages`, `GET/PUT/DELETE /api/v1/messages/<id>` |
| 4 | **Automation** | `automation_controller.py` | `services/automation/` | `GET/POST /api/v1/automations`, `GET/PUT/DELETE /api/v1/automations/<id>` |
| 5 | **AutomationRun** | `automation_run_controller.py` | `services/automation_run/` | `GET/POST /api/v1/automation-runs`, `GET/PUT/DELETE /api/v1/automation-runs/<id>` |
| 6 | **AutomationStepLog** | `automation_step_log_controller.py` | `services/automation_step_log/` | `GET/POST /api/v1/automation-step-logs`, `GET/PUT/DELETE /api/v1/automation-step-logs/<id>` |
| 7 | **AutomationGenerationLog** | `automation_generation_log_controller.py` | `services/automation_generation_log/` | `GET/POST /api/v1/automation-generation-logs`, `GET/PUT/DELETE /api/v1/automation-generation-logs/<id>` |
| 8 | **ExecutionLog** | `execution_log_controller.py` | `services/execution_log/` | `GET/POST /api/v1/execution-logs`, `GET/PUT/DELETE /api/v1/execution-logs/<id>` |
| 9 | **Integration** | `integration_controller.py` | `services/integration/` | `GET/POST /api/v1/integrations`, `GET/PUT/DELETE /api/v1/integrations/<id>` |
| 10 | **MessageFeedback** | `message_feedback_controller.py` | `services/message_feedback/` | `GET/POST /api/v1/message-feedback`, `GET/PUT/DELETE /api/v1/message-feedback/<id>` |
| 11 | **AiSuggestion** | `ai_suggestion_controller.py` | `services/ai_suggestion/` | `GET/POST /api/v1/ai-suggestions`, `GET/PUT/DELETE /api/v1/ai-suggestions/<id>` |
| 12 | **PageContext** | `page_context_controller.py` | `services/page_context/` | `GET/POST /api/v1/page-contexts`, `GET/PUT/DELETE /api/v1/page-contexts/<id>` |
| 13 | **BrowserSession** | `browser_session_controller.py` | `services/browser_session/` | `GET/POST /api/v1/browser-sessions`, `GET/PUT/DELETE /api/v1/browser-sessions/<id>` |
| 14 | **PageAnalysisCache** | `page_analysis_cache_controller.py` | `services/page_analysis_cache/` | `GET/POST /api/v1/page-analysis-cache`, `GET/PUT/DELETE /api/v1/page-analysis-cache/<id>` |
| 15 | **UserDevice** | `user_device_controller.py` | `services/user_device/` | `GET/POST /api/v1/user-devices`, `GET/PUT/DELETE /api/v1/user-devices/<id>` |
| 16 | **UserWebhookConfig** | `user_webhook_config_controller.py` | `services/user_webhook_config/` | `GET/POST /api/v1/user-webhook-configs`, `GET/PUT/DELETE /api/v1/user-webhook-configs/<id>` |
| 17 | **IaMemory** | `ia_memory_controller.py` | `services/ia_memory/` | `GET/POST /api/v1/ia-memories`, `GET/PUT/DELETE /api/v1/ia-memories/<id>` |

**Total: 18 Models × 5 endpoints = 90 rotas CRUD**

## 📋 Pré-requisitos

- Python 3.11+
- Arquivo `.env` configurado (veja `.env.example`)
- (Opcional) Conta Supabase para PostgreSQL

## 🔧 Instalação

```bash
# 1. Clone e entre no diretório
cd backend

# 2. Configure o .env
cp .env.example .env
# Edite com suas credenciais (DATABASE_URL vazio = SQLite local)

# 3. Ambiente virtual
python -m venv venv
.\venv\Scripts\activate  # Windows
# source .venv/bin/activate  # Linux/Mac

# 4. Instalar dependências
pip install -r requirements.txt
```

## 🏃 Executar

### API (modo local)

```bash
cd backend
.\venv\Scripts\activate
python run.py
```

A API estará em http://localhost:8000 | Health: http://localhost:8000/health

### Worker (automações Temporal)

```bash
cd backend
.\venv\Scripts\activate
$env:PYTHONPATH = "."
python -m worker.server
```

### Script de atalho

```powershell
# Da raiz do projeto
.\run_catas.ps1          # Só API
.\run_catas.ps1 -Mode all      # API + Worker
```

## ⚙️ Configuração

Copie `.env.example` para `.env` e preencha as variáveis. As principais:

| Variável | Descrição |
|----------|-----------|
| `DATABASE_URL` | PostgreSQL/outro via SQLAlchemy. Deixe vazio para SQLite local (dev/teste) |
| `OPENAI_API_KEY` | API Key OpenAI |
| `GROQ_API_KEY` | API Key Groq (modelos gratuitos) |
| `ENCRYPTION_KEY` | Chave para criptografia interna |
| `FIREBASE_ADMIN_CREDENTIALS_JSON` | Credenciais do Firebase Admin (JSON) para autenticação |

## 🧪 Testar

```bash
cd backend
.\venv\Scripts\activate
python -m pytest tests/ -v
```

## 🏗️ Arquitetura

### CRUD Flow

```
HTTP POST /api/v1/profiles
  → routes.py → ProfileController.criar()
    → CriarProfileService.executar(dados)
      → Profile(**dados) → profile.salvar()
    → return jsonify(model.to_dict()), 201
```

### Relatórios Flow (além do CRUD — Repository + Procedures)

As consultas complexas do domínio (filtros, buscas, ordenações, agregações, combinação de tabelas com WHERE / ORDER BY / JOIN / GROUP BY) ficam na camada **Repository**, que no PostgreSQL despacha para **procedures** `public.fn_*`. Em dev/teste (SQLite) usa fallback em SQL inline equivalente.

```
HTTP GET /api/v1/relatorios/automacoes?user_id=...&status=...&busca=...
  → routes.py → RelatorioController.relatorio_automacoes()
    → GerarRelatorioAutomacoesService.executar(...)
      → AutomacaoRepository.listar_runs_filtrados(...)
        → SELECT * FROM public.fn_relatorio_automacoes(...)
    → response.jsonify(resultado), 200
```

### Funcionalidades de relatório (esta etapa)

| Funcionalidade | Endpoint | Procedure | Repository |
|----------------|----------|-----------|------------|
| Painel de estatísticas | `GET /api/v1/relatorios/dashboard` | `public.fn_dashboard_estatisticas(user_id, dias DEFAULT 7)` | `DashboardRepository.estatisticas_dashboard` |
| Relatório de automações | `GET /api/v1/relatorios/automacoes` | `public.fn_relatorio_automacoes(user_id, status, data_inicio, data_fim, busca, ordem, limite, deslocamento)` | `AutomacaoRepository.listar_runs_filtrados` |
| Relatório de conversas | `GET /api/v1/relatorios/chat` | `public.fn_relatorio_chat(user_id, dias DEFAULT 30)` | `ChatRepository.relatorio_chat` |
| Busca de mensagens | `GET /api/v1/relatorios/mensagens/busca` | `public.fn_buscar_mensagens(user_id, termo, limite, deslocamento)` | `ChatRepository.buscar_mensagens` |

As procedures estão definidas em `migrations/018_procedures_relatorios.sql`. Para criar no PostgreSQL:

- **Supabase Dashboard**: SQL Editor → cole o conteúdo do arquivo → **Run**
- **Supabase CLI**: `supabase link --project-ref <ref> && supabase db push`

Testes: `tests/test_relatorios.py` cobre os 4 endpoints (com fallback SQLite do Repository).

### Pipeline de IA

```
User Message → Intent Classifier → Entity Extractor → Payload Builder → AI Response
```

### Execução Temporal

```
API Flask → Temporal Client → Temporal Server → Worker → Activities
```

## 📂 Estrutura

```
backend/
├── app/
│   ├── __init__.py         # create_app(), init_firebase()
│   ├── extensions.py       # db = SQLAlchemy()
│   ├── routes.py           # rotas CRUD + relatórios centralizadas
│   ├── models/             # 18 modelos SQLAlchemy com CRUD
│   ├── controllers/        # 18 controllers CRUD + RelatorioController
│   ├── services/           # um service por caso de uso (CRUD + relatório)
│   └── repositories/       # acesso complexo via procedures PostgreSQL
├── core/
│   ├── config.py           # Settings via Pydantic
│   └── errors.py           # Error handling
├── worker/                 # Temporal Worker
├── tests/                  # Testes
├── migrations/             # Migrations SQL (procedures relatórios em 018)
├── run.py                  # Entrypoint
└── requirements.txt
```

## 🔗 Links

- [Frontend](../frontend/README.md)
- [Documentação Geral](../docs/README.md)
