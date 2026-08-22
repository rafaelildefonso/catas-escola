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
| Database | PostgreSQL (Supabase) ou SQLite (dev) |
| Workflows | Temporal.io |
| Auth | Firebase Auth |

---

## Funcionalidades Implementadas

1. **Criar conta (cadastro)** — Tela de cadastro → `POST /api/v1/auth/signup` → `AuthController` → `CriarContaService` → User + Profile
2. **Login/logout (autenticação)** — Tela de login → `POST /api/v1/auth/login` → `AuthController` → `AutenticarUsuarioService` → User
3. **Enviar mensagem no chat com resposta de IA** — Tela de chat → `POST /api/v1/chat/message` → `ChatbotController` → `EnviarMensagemChatService` → AIService (Gemini/Groq) + Message
4. **Gerenciar sessões de chat (criar/listar/renomear/excluir)** — Tela de chat → `GET/POST/PATCH/DELETE /api/v1/chat/sessions` → `ChatController` → services/chat → ChatSession
5. **Listar e gerenciar integrações** — Tela de integrações → `GET/POST/PUT/DELETE /api/v1/integrations` → `IntegrationController` → services/integration → Integration
6. **Cadastrar/listar/atualizar/excluir automações** — Tela de automações → `GET/POST/PUT/DELETE /api/v1/automations` → `AutomationController` → services/automation → Automation
7. **Listar histórico de mensagens** — Tela de chat → `GET /api/v1/chat/history/<session_id>` → `ChatController` → `ObterHistoricoChatService` → Message
8. **Atualizar dados da conta (perfil)** — Tela de configurações → `PUT /api/v1/profiles/<id>` → `ProfileController` → `AtualizarProfileService` → Profile
9. **Painel de estatísticas (dashboard)** — Tela de dashboard → `GET /api/v1/relatorios/dashboard` → `RelatorioController` → `DashboardRepository` → procedure `fn_dashboard_estatisticas`
10. **Busca de mensagens** — Tela de relatórios → `GET /api/v1/relatorios/mensagens/busca` → `RelatorioController` → `ChatRepository` → procedure `fn_buscar_mensagens`

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

Todas as 18 Models do domínio estão implementadas na camada `backend/models/`, herdando de `db.Model` com métodos `salvar()`, `atualizar()`, `deletar()`, `listar_todos()`, `buscar_por_id()` e `to_dict()`.

| # | Model | Tabela | Descrição |
|---|-------|--------|-----------|
| 1 | **User** | `users` | Usuários e credenciais de autenticação |
| 2 | **Profile** | `profiles` | Perfil do usuário, assinatura, cotas |
| 3 | **ChatSession** | `chat_sessions` | Sessões de chat do usuário |
| 4 | **Message** | `messages` | Mensagens do chat (usuário/assistente) |
| 5 | **Automation** | `automations` | Definições de automação |
| 6 | **AutomationRun** | `automation_runs` | Execuções de automação |
| 7 | **AutomationStepLog** | `automation_step_logs` | Logs por passo da automação |
| 8 | **AutomationGenerationLog** | `automation_generation_logs` | Auditoria do planner de IA |
| 9 | **ExecutionLog** | `execution_logs` | Logs legados de execução |
| 10 | **Integration** | `integrations` | Tokens OAuth de integrações |
| 11 | **MessageFeedback** | `message_feedback` | Feedback do usuário nas mensagens |
| 12 | **AiSuggestion** | `ai_suggestions` | Sugestões proativas de IA |
| 13 | **PageContext** | `page_contexts` | Contexto de página analisada |
| 14 | **BrowserSession** | `browser_sessions` | Sessões ativas do navegador |
| 15 | **PageAnalysisCache** | `page_analysis_cache` | Cache de análise de URLs |
| 16 | **UserDevice** | `user_devices` | Tokens FCM para push notification |
| 17 | **UserWebhookConfig** | `user_webhook_configs` | Configurações de webhook |
| 18 | **IaMemory** | `ia_memory` | Memória semântica (RAG) |

## Rotas da API (112 Rotas)

Cada Model possui 5 endpoints REST no padrão `/api/v1/<recursos>`:

| Model | GET (listar) | GET (buscar) | POST (criar) | PUT (atualizar) | DELETE (deletar) |
|-------|-------------|--------------|-------------|-----------------|------------------|
| User | `GET /api/v1/users` | `GET /api/v1/users/<id>` | `POST /api/v1/users` | `PUT /api/v1/users/<id>` | `DELETE /api/v1/users/<id>` |
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

O backend segue a arquitetura com camadas bem definidas, e as consultas mais complexas (além do CRUD básico) são executadas na camada **Repository** por meio de **procedures no banco de dados**:

```
HTTP Request → Route → Controller → Service → Repository → Procedure (PostgreSQL)
                                 └─→ Model (db.Model) → CRUD básico
```

- **Models**: Representam domínio + tabela, com métodos CRUD (`salvar`, `atualizar`, `deletar`, `listar_todos`, `buscar_por_id`, `to_dict`)
- **Services**: Um por caso de uso (criar/listar/buscar/atualizar/deletar/gerar_relatorio/...), com validação de regras de negócio
- **Controllers**: Um por recurso/funcionalidade, recebem HTTP, chamam Services, devolvem JSON
- **Repositories**: Encapsulam consultas além do CRUD (filtros, buscas, ordenações, relatórios, JOINs) via procedures `public.fn_*`; no ambiente de desenvolvimento/teste (SQLite) usam fallback em SQL inline equivalente
- **Routes**: Centralizadas em `routes.py`, mapeiam URL + método HTTP → Controller

```
backend/
├── __init__.py         # create_app(), init_firebase()
├── extensions.py       # db = SQLAlchemy()
├── routes.py           # rotas CRUD + relatórios centralizadas
├── application.py      # create_app()
├── models/             # 18 modelos SQLAlchemy com CRUD
├── controllers/        # 18 controllers CRUD + RelatorioController
├── services/           # um service por caso de uso (CRUD + relatório)
├── repositories/       # acesso complexo via procedures PostgreSQL
├── core/               # Config, error handling
├── worker/             # Temporal Worker
├── tests/              # Testes automatizados
├── migrations/         # Migrations SQL (procedures de relatórios em 018)
├── run.py              # Entrypoint da API
└── run_catas.ps1       # Script de atalho

frontend/               # App Flutter (Dart)
```

## Funcionalidades Além do CRUD (Relatórios) — Esta Etapa

Foram implementadas 4 funcionalidades no backend que exigem consultas complexas ao banco de dados (filtros, buscas, ordenações, agregações, combinação entre tabelas com WHERE / ORDER BY / JOIN / GROUP BY). Toda a lógica de acesso é encapsulada na camada `Repository` e executada por procedures no PostgreSQL (`migrations/018_procedures_relatorios.sql`).

| Funcionalidade | Endpoint | Descrição |
|----------------|----------|-----------|
| **Painel de estatísticas** | `GET /api/v1/relatorios/dashboard` | Contagens, taxa de sucesso, execuções por status, integrações top, total de mensagens por período |
| **Relatório de automações** | `GET /api/v1/relatorios/automacoes` | Execuções filtradas por status/data/busca, com ordenação (`created_at`, `status`, `started_at`, `run_type`) e paginação (`limite`/`deslocamento`) |
| **Relatório de conversas** | `GET /api/v1/relatorios/chat` | Sessões/mensagens, sessões ativas, mensagens por papel (usuário/assistente/sistema), por dia e feedback (likes/dislikes) |
| **Busca de mensagens** | `GET /api/v1/relatorios/mensagens/busca` | Busca por termo (mín. 2 caracteres) no conteúdo/sessões, com paginação |

### Procedures criadas (`backend/migrations/018_procedures_relatorios.sql`)

| Procedure | Parâmetros | Lógica |
|-----------|-----------|--------|
| `public.fn_dashboard_estatisticas(user_id, dias DEFAULT 7)` | `uuid`, `integer` | Agregação multi-tabela, `GROUP BY status`/`date(created_at)`, `jsonb_build_object` |
| `public.fn_relatorio_automacoes(user_id, status, data_inicio, data_fim, busca, ordem, limite, deslocamento)` | `uuid`, `text`, `timestamptz`, `timestamptz`, `text`, `text`, `integer`, `integer` | `LEFT JOIN automations`, filtros dinâmicos, `ORDER BY` (whitelist) e `LIMIT/OFFSET` |
| `public.fn_relatorio_chat(user_id, dias DEFAULT 30)` | `uuid`, `integer` | `JOIN chat_sessions × messages`, `GROUP BY` por papel/dia, agregação de feedback |
| `public.fn_buscar_mensagens(user_id, termo, limite, deslocamento)` | `uuid`, `text`, `integer`, `integer` | Busca `ILIKE` em conteúdo/títulos, `ORDER BY` e paginação |

### Camadas usadas por funcionalidade

| Funcionalidade | Controller | Services | Repositories | Models |
|----------------|-----------|----------|--------------|--------|
| Estatísticas dashboard | `RelatorioController.estatisticas_dashboard` | `GerarEstatisticasDashboardService` | `DashboardRepository.estatisticas_dashboard` | AutomationRun, Integration, ChatSession, Message |
| Relatório de automações | `RelatorioController.relatorio_automacoes` | `GerarRelatorioAutomacoesService` | `AutomacaoRepository.listar_runs_filtrados` | AutomationRun, Automation |
| Relatório de conversas | `RelatorioController.relatorio_chat` | `GerarRelatorioChatService` | `ChatRepository.relatorio_chat` | ChatSession, Message, MessageFeedback |
| Busca de mensagens | `RelatorioController.buscar_mensagens` | `BuscarMensagensService` | `ChatRepository.buscar_mensagens` | ChatSession, Message |

### Executando as procedures no banco

As procedures são criadas pela migration `backend/migrations/018_procedures_relatorios.sql`:

- **Supabase Dashboard**: abra o **SQL Editor**, cole o conteúdo do arquivo e clique em **Run**.
- **Supabase CLI**: `supabase db push` (com `supabase link` já feito).

### Telas no app Flutter

A funcionalidade é acessível pela tela **Relatórios** (`/app/relatorios`), com 3 abas — **Automações** (filtros + ordenação + paginação), **Conversas** (métricas e gráficos) e **Busca de Mensagens** — consumindo os endpoints acima via `RelatorioRepository` → `RelatorioProvider`.

## Testar

1. Com a API rodando, visite http://localhost:8000/health
2. Use o Swagger em `/` para explorar os endpoints
3. Para testes automatizados:

```bash
cd backend
.\venv\Scripts\activate
python -m pytest tests/ -v
```