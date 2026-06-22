# Estrutura do Backend (Server)

O backend do CATAS é desenvolvido em **Python** com **FastAPI**, localizado em `server/`.

## Diretórios e Arquivos

```
server/
├── app/
│   ├── main.py              # Ponto de entrada FastAPI
│   ├── core/
│   │   ├── config.py        # Configurações e variáveis de ambiente
│   │   └── security.py      # Autenticação JWT/Bearer
│   ├── models/              # Modelos Pydantic (request/response)
│   ├── routers/
│   │   ├── chat.py          # CRUD de sessões e mensagens
│   │   ├── automations.py   # Execução de planos via Temporal.io
│   │   ├── payments.py      # Stripe Checkout/Subscription
│   │   └── webhooks.py      # Callbacks Stripe
│   ├── repositories/
│   │   ├── chat.py          # Acesso a chat_sessions e messages
│   │   ├── profiles.py      # Perfis de usuário e cotas de crédito
│   │   └── automation_runs.py # Histórico de execuções Temporal.io
│   └── services/
│       ├── ai_base.py       # Chamada unificada às APIs de IA (Token tracking)
│       ├── ai_service.py    # Orquestrador Maestro (Intent, Entity, Response)
│       ├── automation_pipeline_service.py # Maestro Pipeline (Planner/Validator)
│       ├── temporal_service.py # Core do Temporal.io (Workflow Starter)
│       └── ia_memory.py     # Busca Semântica / RAG (pgvector)
├── worker/                  # Workers e Activities do Temporal.io
│   ├── main.py              # Entry point do Worker
│   ├── workflows/           # Definição de Workflows (AutomationWorkflow)
│   └── activities/          # Ações atômicas (Google, Meta, WhatsApp)
├── requirements.txt
└── .env
```

## Fluxo Principal: Chat

1. **Frontend** envia `POST /api/v1/chat/message`.
2. **Backend (AIService)**:
   - **Router**: Detecta se é conversa ou intenção de automação.
   - **Planner**: Se for automação, gera um `AutomationPlan` validado.
   - **Temporal**: Se o plano for aprovado/finalizado, o `TemporalService` inicia o workflow no Cluster Temporal.
   - **Streaming**: O status de cada Activity do Temporal é enviado em tempo real ao app via SSE ou Realtime DB.
   - **Créditos**: O custo total de tokens da interação é debitado do perfil do usuário (2k tokens = 1 credit).
3. **Persistência**: O plano e os resultados são salvos em `automation_runs`.

## Repositories

| Arquivo              | Tabela(s)                   | Funções Principais                                                                       |
| -------------------- | --------------------------- | --------------------------------------------------------------------------------------- |
| `chat.py`            | `chat_sessions`, `messages` | create_session, get_user_sessions, save_message, get_session_messages, delete_session   |
| `automation_logs.py` | `automation_logs`           | log_automation, get_user_automation_logs, get_automation_stats                          |
| `automations.py`     | `automations`               | save_automation_history, update_automation_status                                       |
| `profiles.py`        | `profiles`                  | get_user_profile, create_default_profile, increment_quota_usage, get_quota_config       |

### Persistência de Contexto

O campo `metadata` da tabela `messages` armazena o estado complexo da resposta da IA:

- `components`: JSON dos componentes de UI exibidos.
- `status`: Estado conversacional (`requires_action`, `completed`).
- `action_triggered`: Se uma ação foi identificada para execução.
- `is_hidden`: Se a mensagem deve ser oculta do histórico visual do usuário (usado para callbacks de componentes).

**Nota:** Automações no banco:

- `execution_logs`: correlaciona disparos iniciados pelo chat (id reutilizado como `automation_id` no Temporal).
- `automations`: definições (gatilho + steps JSONB).
- `automation_runs`: histórico por execução (Temporal / n8n); alimenta métricas e callbacks.
- `automation_step_logs`: progresso por step (worker + Realtime).
- `automation_generation_logs`: auditoria de geração de planos (Maestro).
- `automation_logs` (migration 002 / legado nome): uso legado em alguns ambientes — não confundir com `automation_generation_logs`.

Execuções via `POST /api/v1/execute/action` registram linhas em `automation_runs` (`run_type = n8n`).

Matriz RLS: [RLS_MATRIX.md](../../server/migrations/RLS_MATRIX.md).

## Segurança

- **get_current_user**: Valida Bearer token via Supabase `auth.get_user()`.
- **verify_n8n_webhook**: Valida header `X-N8N-Webhook-Secret` em callbacks n8n.
- **RLS**: O Supabase aplica Row Level Security; o backend usa `SUPABASE_SERVICE_ROLE_KEY` (bypassa RLS para operações server-side).

## Configuração

Veja [variáveis de ambiente](../comecando/variaveis-ambiente.md).

## Como Rodar

```powershell
cd server
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

API disponível em `http://127.0.0.1:8000`. Swagger em `http://127.0.0.1:8000/docs`.
