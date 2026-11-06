# CATAS Backend API

Backend Flask do CATAS — Sistema de Automação de Tarefas com IA.

## Funcionalidades Implementadas

1. **Autenticacao via Firebase Auth** — Signup/login/logout com Bearer Token, rate limiting por IP, criptografia AES de refresh tokens OAuth
2. **CRUD completo (18 entidades)** — User, Profile, ChatSession, Message, Automation, AutomationRun, AutomationStepLog, AutomationGenerationLog, ExecutionLog, Integration, MessageFeedback, AiSuggestion, PageContext, BrowserSession, PageAnalysisCache, UserDevice, UserWebhookConfig, IaMemory — cada uma com Model + 5 Services + 1 Controller + 5 rotas REST
3. **Chat com IA multi-agente** — Pipeline Intent Classifier → Entity Extractor → Payload Builder → Response, suporte a sessoes, historico, continuacao de mensagens, modelos Groq/Gemini/Google
4. **Automacoes multi-step** — Criacao/edicao/exclusao de automacoes com steps, execucao assincrona via worker FastAPI, runner modular com registry de modulos, logs de execucao e step
5. **Relatorios via Repository + Procedures PostgreSQL** — Dashboard de estatisticas, relatorio de automacoes, relatorio de chat, busca de mensagens com filtros avancados (fallback SQLite em dev/teste)
6. **Sistema de creditos** — Controle de uso por usuario via Profile.credits, verificacao de quota antes de operacoes, atualizacao apos uso
7. **Integracoes externas** — Google Calendar/Gmail/Sheets via OAuth, registro de devices FCM para push notifications, webhooks configuraveis por usuario
8. **Feedback de mensagens** — Like/dislike com motivo em mensagens do chat, armazenamento via MessageFeedback
9. **AI Suggestions** — Sugestoes contextuais geradas pela IA para o usuario
10. **Worker FastAPI separado** — Processo de automacoes como servidor FastAPI, compartilha ORM com Flask via `worker/repositorio_dados.py`, server-sent events para progresso em tempo real

## Arquitetura (camadas professor)

```
backend/
    controllers/       # Classes, um por recurso (ChatController, RelatorioController...)
    services/          # Um service por caso de uso (services/chat/, services/ia/...)
    models/            # db.Model com salvar/atualizar/deletar/listar_todos/buscar_por_id/to_dict
    repositories/      # Apenas para queries especiais (filtros, procedures, relatorios)
    routes.py          # Registro centralizado de rotas
    extensions.py      # db = SQLAlchemy()
    application.py     # create_app(), init_firebase()
```

### Fluxo CRUD

```
HTTP POST /api/v1/profiles
  -> routes.py -> ProfileController.criar()
    -> CriarProfileService.executar(dados)
      -> Profile(**dados) -> profile.salvar()
    -> return jsonify(model.to_dict()), 201
```

### Fluxo Relatorios (Repository + Procedures)

```
HTTP GET /api/v1/relatorios/automacoes?status=success&busca=...
  -> routes.py -> RelatorioController.relatorio_automacoes()
    -> GerarRelatorioAutomacoesService.executar(...)
      -> AutomacaoRepository.listar_runs_filtrados(...)
        -> SELECT * FROM public.fn_relatorio_automacoes(...)
```

## 18 Entidades CRUD

| # | Model | Controller | Services | Rotas |
|---|-------|-----------|----------|-------|
| 1 | User | `user_controller.py` | `services/user/` | `GET/POST /users`, `GET/PUT/DELETE /users/<id>` |
| 2 | Profile | `profile_controller.py` | `services/profile/` | `GET/POST /profiles`, `GET/PUT/DELETE /profiles/<id>` |
| 3 | ChatSession | `chat_session_controller.py` | `services/chat_session/` | `GET/POST /chat-sessions`, `GET/PUT/DELETE /chat-sessions/<id>` |
| 4 | Message | `message_controller.py` | `services/message/` | `GET/POST /messages`, `GET/PUT/DELETE /messages/<id>` |
| 5 | Automation | `automation_controller.py` | `services/automation/` | `GET/POST /automations`, `GET/PUT/DELETE /automations/<id>` |
| 6 | AutomationRun | `automation_run_controller.py` | `services/automation_run/` | `GET/POST /automation-runs`, `GET/PUT/DELETE /automation-runs/<id>` |
| 7 | AutomationStepLog | `automation_step_log_controller.py` | `services/automation_step_log/` | `GET/POST /automation-step-logs`, `GET/PUT/DELETE /automation-step-logs/<id>` |
| 8 | AutomationGenerationLog | `automation_generation_log_controller.py` | `services/automation_generation_log/` | `GET/POST /automation-generation-logs`, `GET/PUT/DELETE /automation-generation-logs/<id>` |
| 9 | ExecutionLog | `execution_log_controller.py` | `services/execution_log/` | `GET/POST /execution-logs`, `GET/PUT/DELETE /execution-logs/<id>` |
| 10 | Integration | `integration_controller.py` | `services/integration/` | `GET/POST /integrations`, `GET/PUT/DELETE /integrations/<id>` |
| 11 | MessageFeedback | `message_feedback_controller.py` | `services/message_feedback/` | `GET/POST /message-feedback`, `GET/PUT/DELETE /message-feedback/<id>` |
| 12 | AiSuggestion | `ai_suggestion_controller.py` | `services/ai_suggestion/` | `GET/POST /ai-suggestions`, `GET/PUT/DELETE /ai-suggestions/<id>` |
| 13 | PageContext | `page_context_controller.py` | `services/page_context/` | `GET/POST /page-contexts`, `GET/PUT/DELETE /page-contexts/<id>` |
| 14 | BrowserSession | `browser_session_controller.py` | `services/browser_session/` | `GET/POST /browser-sessions`, `GET/PUT/DELETE /browser-sessions/<id>` |
| 15 | PageAnalysisCache | `page_analysis_cache_controller.py` | `services/page_analysis_cache/` | `GET/POST /page-analysis-cache`, `GET/PUT/DELETE /page-analysis-cache/<id>` |
| 16 | UserDevice | `user_device_controller.py` | `services/user_device/` | `GET/POST /user-devices`, `GET/PUT/DELETE /user-devices/<id>` |
| 17 | UserWebhookConfig | `user_webhook_config_controller.py` | `services/user_webhook_config/` | `GET/POST /user-webhook-configs`, `GET/PUT/DELETE /user-webhook-configs/<id>` |
| 18 | IaMemory | `ia_memory_controller.py` | `services/ia_memory/` | `GET/POST /ia-memories`, `GET/PUT/DELETE /ia-memories/<id>` |

## Rotas extras (nao-CRUD)

| Rota | Metodo | Descricao |
|------|--------|-----------|
| `/api/v1/auth/signup` | POST | Cadastro |
| `/api/v1/auth/login` | POST | Login |
| `/api/v1/auth/me` | GET | Dados do usuario logado |
| `/api/v1/chat/sessions` | GET/POST | Listar/criar sessoes |
| `/api/v1/chat/sessions/<id>/title` | PATCH | Renomear sessao |
| `/api/v1/chat/history/<session_id>` | GET | Historico de mensagens |
| `/api/v1/chat/message` | POST | Enviar mensagem ao chatbot |
| `/api/v1/chat/message/continue` | POST | Continuar resposta com componente |
| `/api/v1/chat/messages/<id>/feedback` | POST | Like/dislike em mensagem |
| `/api/v1/relatorios/dashboard` | GET | Estatisticas do painel |
| `/api/v1/relatorios/automacoes` | GET | Relatorio de automacoes |
| `/api/v1/relatorios/chat` | GET | Relatorio de conversas |
| `/api/v1/relatorios/mensagens/busca` | GET | Busca de mensagens |
| `/api/v1/relatorios/export` | GET | Exporta relatórios em CSV, XLSX ou PDF |
| `/api/v1/billing/checkout` | POST | Cria uma sessão Stripe Checkout autenticada |
| `/api/v1/billing/portal` | POST | Abre o portal de gerenciamento Stripe |
| `/api/v1/billing/webhook` | POST | Sincroniza assinaturas e créditos via webhook assinado |
| `/api/v1/attachments` | GET/POST | Lista anexos do usuário ou envia imagem/PDF/DOCX |
| `/api/v1/attachments/<id>` | DELETE | Exclui um arquivo do usuário autenticado |
| `/api/v1/attachments/<id>/preview` | GET | Retorna texto extraído de DOCX para pré-visualização |
| `/health` | GET | Health check |

**Total: 112 rotas**

### Relatórios, cobrança e arquivos

- A exportação aceita `tipo=automacoes|chat` e `format=csv|xlsx|pdf`. A exportação de automações aplica os filtros atuais e percorre todas as páginas até 10.000 registros.
- Configure `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` e os Price IDs em `BASIC_PLAN_ID`, `PRO_PLAN_ID` e `MAX_PLAN_ID`. Registre `/api/v1/billing/webhook` no Stripe para `checkout.session.completed`, `customer.subscription.*` e `invoice.*`.
- Configure `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` para ativar uploads. Os arquivos são guardados em bucket privado, com links assinados temporários, limite de 10 MB e autorização por usuário. A migration `019_billing_and_attachments.sql` cria as colunas de billing e os metadados de anexos.
- `FRONTEND_URL` controla o retorno do portal Stripe; `STRIPE_SUCCESS_URL` e `STRIPE_CANCEL_URL` podem sobrescrever os destinos do Checkout.

## Pre-requisitos

- Python 3.11+
- Arquivo `.env` configurado (veja `.env.example`)

## Instalacao

```bash
cd backend
cp .env.example .env
python -m venv venv
.\venv\Scripts\activate    # Windows
pip install -r requirements.txt
```

## Executar

```bash
# API
python run.py

# Worker (automacoes)
python -m worker.entrypoint

# Scheduler (obrigatorio para automacoes recorrentes)
python -m services.automation.scheduler
```

## Testar

```bash
python -m pytest tests/ -v
```
# Automações agendadas

Automações salvas aceitam gatilho `manual`, `schedule` com `interval_minutes`
(1 a 10080), ou `cron` com cinco campos numéricos em UTC. Ative a automação
para iniciar o agendamento. A próxima execução fica em `automations.next_run_at`.

No Docker Compose, o serviço `scheduler` consulta as automações vencidas a cada
15 segundos e cria um registro em `automation_runs` antes de enviar o plano ao
worker. Para executar localmente, inicie o backend e o worker, depois rode
`python -m services.automation.scheduler` em `backend/`. Em bancos MySQL já
existentes, aplique `migrations/020_automation_scheduler.sql` antes de iniciar
o scheduler. Configure o mesmo `WORKER_SHARED_SECRET` no servidor e no worker.

`POST /api/v1/automations/{id}/schedule` recebe
`{"trigger":{"type":"cron","cron_expression":"0 9 * * 1-5"}}` ou
`{"trigger":{"type":"schedule","interval_minutes":60}}`. O endpoint
`POST /api/v1/automations/{id}/run` dispara uma execução manual. Os dois
exigem Bearer token e só acessam automações do usuário autenticado.

O módulo `gmail.send_email` aceita `attachment_ids`, uma lista de até cinco
IDs de arquivos do próprio usuário já enviados a `/api/v1/attachments`.
Concluir ou falhar uma execução gera uma notificação em `/api/v1/notifications`
e envia push FCM para os dispositivos ativos quando o Firebase está configurado.
