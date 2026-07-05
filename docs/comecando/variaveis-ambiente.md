# Variaveis de Ambiente

Este documento lista todas as variaveis de ambiente utilizadas pelo projeto CATAS.

---

## Backend (backend/)

Crie um arquivo `.env` na raiz de `backend/` com as seguintes variaveis:

### Autenticacao e Banco

| Variavel | Obrigatoria | Descricao |
|---|---|---|
| `SUPABASE_URL` | Sim | URL do projeto Supabase (para validar JWT) |
| `SUPABASE_SERVICE_ROLE_KEY` | Sim | Chave de servico (Service Role) para auth |
| `DATABASE_URL` | Sim | Connection string PostgreSQL (`postgresql://user:pass@host:port/db`) |

### APIs de IA

| Variavel | Obrigatoria | Descricao |
|---|---|---|
| `GROQ_API_KEY` | Condicional | Chave do Groq (recomendado) |
| `GOOGLE_API_KEY` | Condicional | Chave do Gemini (Google AI Studio) |
| `OPENAI_API_KEY` | Condicional | Chave do OpenAI |
| `TOKENS_PER_CREDIT` | Nao | Taxa de conversao tokens->credito. Padrao: `2000` |

### Modelos de IA (Formato: `provider|model|api_url|env_key`)

| Variavel | Papel |
|---|---|
| `AGENT_INTENT_CLASSIFIER` | Classifica a intencao da mensagem |
| `AGENT_ENTITY_EXTRACTOR` | Extrai entidades (datas, nomes, valores) |
| `AGENT_INTERPRETER` | Interpreta a ideia do usuario |
| `AGENT_CLASSIFIER` | Decide se vai para automacao ou conversa |
| `AGENT_SELECTOR` | Escolhe e adapta o fluxo de automacao |
| `AGENT_DEVELOPER` | Gera codigo Python para automacoes |
| `AGENT_WORKER_TRANSFORM` | Transformacao de dados no Worker |
| `MODEL_TIER_BASIC` | Modelo para plano Basic |
| `MODEL_TIER_PRO` | Modelo para plano Pro |
| `MODEL_TIER_MAX` | Modelo para plano Max |

**Exemplo de valor:**
```env
AGENT_INTENT_CLASSIFIER=groq|llama-3.3-70b-versatile|https://api.groq.com/openai/v1|GROQ_API_KEY
```

### Stripe (Billing)

| Variavel | Obrigatoria | Descricao |
|---|---|---|
| `STRIPE_SECRET_KEY` | Sim (SaaS) | Chave secreta do Stripe |
| `STRIPE_WEBHOOK_SECRET` | Sim (SaaS) | Segredo do Webhook do Stripe |
| `BASIC_PLAN_ID` | Sim (SaaS) | ID do Price do plano Basic no Stripe |
| `PRO_PLAN_ID` | Sim (SaaS) | ID do Price do plano Pro no Stripe |
| `MAX_PLAN_ID` | Sim (SaaS) | ID do Price do plano Max no Stripe |

### Google OAuth

| Variavel | Obrigatoria | Descricao |
|---|---|---|
| `GOOGLE_CLIENT_ID` | Sim (integracoes) | Client ID do Google OAuth |
| `GOOGLE_CLIENT_SECRET` | Sim (integracoes) | Client Secret do Google OAuth |

### Firebase

| Variavel | Obrigatoria | Descricao |
|---|---|---|
| `FIREBASE_ADMIN_SDK_JSON_PATH` | Nao | Caminho do service account JSON |
| `FIREBASE_ADMIN_CREDENTIALS_JSON` | Nao | Conteudo JSON inline das credenciais |

### Aplicacao

| Variavel | Obrigatoria | Descricao |
|---|---|---|
| `ENVIRONMENT` | Nao | `development` ou `production` |
| `ENCRYPTION_KEY` | Sim | Chave para criptografia interna |
| `APP_DEEP_LINK_SCHEME` | Nao | Esquema de deep link (ex: `catas`) |
| `DEMO_ONBOARDING_ENABLED` | Nao | `true` para onboarding demo |
| `WORKER_URL` | Sim | URL do Worker (`http://localhost:8001`) |
| `ENABLE_WORKER_DATA_LOGS` | Nao | Logs detalhados do Worker |

### Exemplo .env (Backend)

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
DATABASE_URL=postgresql://postgres.abc123:password@aws-0-us-east-1.pooler.supabase.com:6543/postgres
GROQ_API_KEY=gsk_...

# Creditos (padrao 2000 tokens = 1 credito)
TOKENS_PER_CREDIT=2000

# Agentes de IA
AGENT_INTENT_CLASSIFIER=groq|llama-3.3-70b-versatile|https://api.groq.com/openai/v1|GROQ_API_KEY
AGENT_INTERPRETER=groq|llama-3.3-70b|https://api.groq.com/openai/v1|GROQ_API_KEY

# Google OAuth
GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-...

# Stripe (opcional no desenvolvimento)
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Worker
WORKER_URL=http://localhost:8001

ENVIRONMENT=development
```

---

## App Flutter (app_flutter/)

Crie um arquivo `.env` na raiz de `app_flutter/`:

| Variavel | Obrigatoria | Descricao |
|---|---|---|
| `SUPABASE_URL` | Sim | URL do projeto Supabase |
| `SUPABASE_ANON_KEY` | Sim | Chave anonima do Supabase (publica) |
| `API_BASE_URL` | Condicional | URL base da API (ex: `http://10.0.2.2:8000`) |
| `DEMO_MODE` | Nao | `true` para usar dados mockados |
| `WEB_CLIENT_ID` | Sim (Google) | Client ID do Google OAuth (Web) |
| `ANDROID_CLIENT_ID` | Sim (Android) | Client ID do Google OAuth (Android) |
| `IOS_CLIENT_ID` | Sim (iOS) | Client ID do Google OAuth (iOS) |
| `CLOUDINARY_CLOUD_NAME` | Nao | Nome do cloud Cloudinary para upload |

### Exemplo .env (Flutter)

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=eyJ...

# Desenvolvimento
API_BASE_URL=http://10.0.2.2:8000
DEMO_MODE=false

# Google OAuth
WEB_CLIENT_ID=xxx.apps.googleusercontent.com
ANDROID_CLIENT_ID=xxx.apps.googleusercontent.com
IOS_CLIENT_ID=xxx.apps.googleusercontent.com
```

### Notas para Dispositivos

- **Android Emulator**: Use `10.0.2.2` em vez de `127.0.0.1` para acessar o localhost do host.
- **iOS Simulator**: Use `127.0.0.1` ou `localhost`.
- **Web**: Use `http://localhost:8000` ou a URL do backend em producao.
