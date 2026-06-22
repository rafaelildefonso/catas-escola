# CATAS Backend API

Backend FastAPI do CATAS - Sistema de Automação de Tarefas com IA usando Temporal.io.

## 🚀 Funcionalidades

- ✅ API REST com FastAPI
- ✅ Autenticação via Supabase Auth (Bearer Token)
- ✅ Pipeline de IA multi-agente (Intent → Entities → Action)
- ✅ Orquestração de automações com Temporal.io
- ✅ Integrações: Google Calendar, Gmail, Google Sheets
- ✅ Sistema de créditos por uso de tokens
- ✅ Notificações push via Firebase
- ✅ Webhooks para Stripe (assinaturas)

## 📋 Pré-requisitos

**Para Docker (recomendado):**
- Docker e Docker Compose
- Arquivo `.env` configurado (veja `.env.example`)

**Para desenvolvimento local:**
- Python 3.10+
- Variáveis de ambiente configuradas (veja `.env.example`)

## 🔧 Instalação

### Opção 1: Docker (Recomendado)

Roda tudo (API + Worker + PostgreSQL) com Docker Compose.

#### Pré-requisitos
- Docker e Docker Compose instalados
- Arquivo `.env` configurado (veja abaixo)

#### Passo a passo

```bash
# 1. Configure o .env
cd server
cp .env.example .env
# Edite o .env com suas credenciais

# 2. Suba o Temporal Server (em um terminal)
cd server/docker/temporal
docker-compose up -d

# 3. Na RAIZ do projeto, suba Server + Worker + DB (em outro terminal)
# Atenção: execute este comando na pasta CATAS - Escola, não na pasta server
cd "CATAS - Escola"
docker-compose -f server/docker-compose.yml up -d --build

# 4. Verificar logs
docker-compose -f server/docker-compose.yml logs -f server
docker-compose -f server/docker-compose.yml logs -f worker
```

**Acesso:**
- API: http://localhost:8000
- Docs: http://localhost:8000/docs
- Temporal UI: http://localhost:8080

#### Parar tudo

```bash
# Parar Server + Worker + DB (na raiz do projeto)
docker-compose -f server/docker-compose.yml down

# Parar Temporal
cd server/docker/temporal
docker-compose down
```

---

### Opção 2: Local (sem Docker)

Use apenas para desenvolvimento do código Python.

```bash
cd server

# Criar ambiente virtual
python -m venv venv

# Ativar ambiente
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Instalar dependências
python -m pip install -r requirements.txt

# Rodar o servidor
uvicorn app.main:app --reload
```


## ⚙️ Configuração

Crie um arquivo `.env` na raiz do diretório `server/`:

```env
# === SUPABASE ===

SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=

# === IA ===

OPENAI_API_KEY=
GOOGLE_API_KEY=
GROQ_API_KEY=

# MODELS

# Chat Padrão (Multimodal/Visão)
MODEL_TIER_BASIC=ai|ai-model|ai-api-url|env-key-ai-api-key
MODEL_TIER_PRO=ai|ai-model|ai-api-url|env-key-ai-api-key
MODEL_TIER_MAX=ai|ai-model|ai-api-url|env-key-ai-api-key

# Classifica se é conversa ou ação (recomendo um modelo rápido)
AGENT_INTENT_CLASSIFIER=ai|ai-model|ai-api-url|env-key-ai-api-key

# Extrai nomes, datas e emails (recomendo um modelo preciso)
AGENT_ENTITY_EXTRACTOR=ai|ai-model|ai-api-url|env-key-ai-api-key

# Interpreta a ideia do usuário
AGENT_INTERPRETER=ai|ai-model|ai-api-url|env-key-ai-api-key
# Classifica a intenção do usuário
AGENT_CLASSIFIER=ai|ai-model|ai-api-url|env-key-ai-api-key
# Seleciona ferramentas e nós
AGENT_SELECTOR=ai|ai-model|ai-api-url|env-key-ai-api-key
# Escreve o código Python final / Workflow Temporal
AGENT_DEVELOPER=ai|ai-model|ai-api-url|env-key-ai-api-key


# === STRIPE ===

# TEST
# STRIPE_SECRET_KEY=
# STRIPE_WEBHOOK_SECRET=
# BASIC_PLAN_ID=
# PRO_PLAN_ID=
# MAX_PLAN_ID=

# LOCAL TEST
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
BASIC_PLAN_ID=
PRO_PLAN_ID=
MAX_PLAN_ID=

# PRODUCTION
# STRIPE_SECRET_KEY=
# STRIPE_WEBHOOK_SECRET=
# BASIC_PLAN_ID=
# PRO_PLAN_ID=
# MAX_PLAN_ID=

# === APP ===
APP_DEEP_LINK_SCHEME=catas

# === Criptografia Interna ===
ENCRYPTION_KEY=

# === Servidor ===
ENVIRONMENT=development|production
```

## 🏃 Executar (modo local)

Se estiver rodando sem Docker:

```bash
# Ativar ambiente
venv\Scripts\activate  # Windows
source venv/bin/activate  # Linux/Mac

# Rodar o servidor
uvicorn app.main:app --reload
```

A API estará disponível em:
- API: http://127.0.0.1:8000
- Docs: http://127.0.0.1:8000/docs

## 📡 Endpoints

### `POST /api/v1/analyze/page`
Analisa uma página web e retorna sugestões de automação.

**Headers:**
```
Authorization: Bearer <supabase_jwt_token>
```

**Body:**
```json
{
  "url": "https://example.com",
  "html_content": "<html>...</html>",
  "user_context": "Contexto adicional (opcional)"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Página analisada com sucesso",
  "data": {
    "summary": "Resumo da página",
    "suggested_actions": [
      {
        "type": "calendar",
        "title": "Agendar Reunião",
        "description": "...",
        "confidence": 0.9,
        "extracted_data": {}
      }
    ],
    "quota_remaining": 4
  }
}
```

### `POST /api/v1/execute/action`
Executa uma ação de automação.

**Headers:**
```
Authorization: Bearer <supabase_jwt_token>
```

**Body:**
```json
{
  "action_type": "calendar",
  "payload": {
    "title": "Reunião",
    "date": "2024-01-01T14:00:00Z"
  }
}
```

### `GET /api/v1/user/me`
Retorna informações do perfil do usuário.

**Headers:**
```
Authorization: Bearer <supabase_jwt_token>
```

**Response:**
```json
{
  "status": "success",
  "message": "Perfil recuperado com sucesso",
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "subscription_tier": "free",
    "daily_quota_limit": 5,
    "quota_used_today": 1,
    "quota_remaining": 4
  }
}
```

## 🗄️ Estrutura do Banco de Dados

### Tabela `profiles`
- `id` (uuid, PK) - ID do usuário (mesmo do auth.users)
- `email` (text)
- `subscription_tier` (text) - 'free' ou 'pro'
- `daily_quota_limit` (int) - Limite diário de automações
- `quota_used_today` (int) - Automações usadas hoje
- `last_quota_reset` (timestamp) - Último reset de cota

### Tabela `automations`
- `id` (uuid, PK)
- `user_id` (uuid, FK)
- `type` (text) - Tipo de automação
- `status` (text) - 'pending', 'completed', 'failed'
- `input_summary` (text)
- `input_payload` (jsonb)
- `result_metadata` (jsonb)
- `created_at` (timestamp)

## 🔒 Segurança

- Todas as rotas (exceto `/health`) requerem autenticação via Bearer Token
- Tokens são validados com o Supabase Auth
- HTML é sanitizado antes de ser enviado para OpenAI
- Cotas são verificadas antes de processar análises

## 📝 Notas

- A cota é resetada automaticamente a cada novo dia
- Perfis são criados automaticamente no primeiro uso (free tier)
- O HTML é limitado a 50k caracteres para evitar custos excessivos

---

## 🏗️ Arquitetura

### Pipeline de IA

```
User Message → Intent Classifier → Entity Extractor → Payload Builder → AI Response
                    ↓                      ↓                  ↓
              conversation          calendar_create      action_details
              calendar_create       task_create          (JSON para Temporal)
              task_create           email_draft
              email_draft
```

### Execução Temporal

```
API FastAPI → Temporal Client → Temporal Server → Worker → Activities
   (chat)          (plan)           (orquestra)      (run)   (executa)
                                              ↓
                                        create_calendar
                                        send_email
                                        debit_credits
```

## 🐳 Setup Temporal (Docker)

O **Temporal Server** é necessário para orquestrar as automações. Está em `server/docker/temporal/`.

### Subir o Temporal

```bash
cd docker/temporal
docker-compose up -d

# Aguarde 30-60 segundos para inicializar completamente
docker ps
# Deve mostrar: temporal, temporal-ui, temporal-postgresql, temporal-elasticsearch
```

**Acesse a UI:** http://localhost:8080

### Variáveis de ambiente

Adicione ao `.env`:

```env
# === TEMPORAL ===
TEMPORAL_HOST=localhost:7233
TEMPORAL_NAMESPACE=default
TEMPORAL_TASK_QUEUE=automation-queue
```

### Rodar o Worker (modo local)

Se estiver rodando sem Docker, ative o venv e rode:

```bash
venv\Scripts\activate
$env:PYTHONPATH = "."
python worker/main.py

# Deve aparecer:
# 🚀 Worker ativo — task_queue: 'automation-queue'
```

**Nota:** Se estiver usando Docker, o Worker já roda automaticamente via `docker-compose`.

## 📂 Estrutura do Projeto

```
server/
├── app/
│   ├── api/               # Rotas FastAPI
│   ├── services/          # Lógica de IA
│   │   ├── ai_service.py
│   │   ├── entity_extractor.py
│   │   ├── intent_classifier.py
│   │   └── payload_builder.py
│   └── repositories/      # Acesso a dados
├── worker/                # Temporal Worker
│   ├── main.py            # Entrypoint do worker
│   ├── workflows/         # Temporal Workflows
│   │   └── automation_workflow.py
│   └── activities/        # Temporal Activities
│       ├── calendar/
│       ├── gmail/
│       └── utils/
├── docker/
│   └── temporal/          # Docker Compose do Temporal
├── migrations/            # SQL migrations
└── requirements.txt
```

## 🔗 Links

- [App Flutter](../app_flutter/README.md)
- [Documentação Geral](../PROJECT_CONTEXT.md)
