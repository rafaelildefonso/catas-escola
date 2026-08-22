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
| `/health` | GET | Health check |

**Total: 112 rotas**

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
python -m worker.server
```

## Testar

```bash
python -m pytest tests/ -v
```
