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
  app.py                           # Entrypoint Flask
  core/
    config.py                      # Config e variaveis de ambiente
    security.py                    # Autenticacao JWT/Bearer (Supabase)
    errors.py                      # Manipulacao de erros
  controllers/                     # Blueprints Flask
    user.py                        # CRUD de perfil
    chat.py                        # CRUD de sessoes
    chatbot.py                     # POST /api/v1/chat/message
    automations.py                 # Automacoes
    integrations.py                # Google OAuth
    payments.py                    # Stripe
    feedback.py                    # Feedback
    webhooks.py                    # Webhooks Stripe
    webhook_receiver.py            # Webhooks externos
    prompt_improve.py              # Melhoria de prompt
  models/
    db_models.py                   # 17 modelos SQLAlchemy
  services/
    database.py                    # Engine SQLAlchemy, SessionLocal
    ai_service.py                  # Orquestrador Maestro
    ai_base.py                     # Provider base
    ai_providers/                  # Gemini, Groq, OpenAI
    intent_classifier.py           # Classificador de intencao
    entity_extractor.py            # Extrator de entidades
    payload_builder.py             # Montagem de payload
    ui_components_library.py       # Biblioteca de componentes
    credit_service.py              # Gestao de creditos (atomico)
    ia_memory.py                   # Busca semantica pgvector
    notification_service.py        # Push FCM
  repositories/                    # Acesso a dados (SQLAlchemy)
    profiles.py, chat.py, automations.py, ...
  worker/
    server.py                      # Servidor FastAPI
    runner.py                      # Motor de execucao
    modules/                       # Modulos de automacao
  migrations/
  tests/
  requirements.txt
  .env
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

## Repositories

Cada repository encapsula queries SQLAlchemy para uma ou mais tabelas:

| Arquivo | Tabela(s) | Funcoes Principais |
|---|---|---|
| `chat.py` | `chat_sessions`, `messages` | create_session, save_message, get_session_messages |
| `automations.py` | `automations` | save_automation_history, update_status |
| `automation_logs.py` | `automation_logs` | log_automation, get_stats |
| `profiles.py` | `profiles` | get_user_profile, create_default_profile, increment_quota |

---

## Seguranca

- **get_current_user**: Valida Bearer token via `GET {SUPABASE_URL}/auth/v1/user`.
- **login_required**: Decorator que bloqueia rotas nao autenticadas.
- **Dev token**: Em ambiente `development`, aceita `Authorization: Bearer dev-token`.

---

## Configuracao

Veja [variaveis de ambiente](../comecando/variaveis-ambiente.md).

---

## Como Rodar

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
flask run --port 8000 --debug
```

API disponivel em `http://127.0.0.1:8000`.
