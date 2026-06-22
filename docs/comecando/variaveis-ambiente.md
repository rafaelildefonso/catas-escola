# Variáveis de Ambiente

Este documento lista todas as variáveis de ambiente utilizadas pelo projeto CATAS.

## Backend (server/)

Crie um arquivo `.env` na raiz de `server/` com as seguintes variáveis:

### Banco de Dados e Auth

| Variável                    | Obrigatória | Descrição                              |
| --------------------------- | ----------- | -------------------------------------- |
| `SUPABASE_URL`              | Sim         | URL do projeto Supabase                |
| `SUPABASE_SERVICE_ROLE_KEY` | Sim         | Chave de serviço (Service Role)        |

### APIs de IA

| Variável                    | Obrigatória | Descrição                              |
| --------------------------- | ----------- | -------------------------------------- |
| `GOOGLE_API_KEY`            | Condicional | Chave do Gemini (Google AI Studio)     |
| `OPENAI_API_KEY`            | Condicional | Chave do OpenAI                        |
| `GROQ_API_KEY`              | Condicional | Chave do Groq                          |
| `TOKENS_PER_CREDIT`         | Não         | Taxa de conversão tokens→crédito. Padrão: `2000` |

### Modelos de IA (Formato: `provider|model|api_url|env_key`)

| Variável                    | Papel                                          |
| --------------------------- | ---------------------------------------------- |
| `AGENT_INTENT_CLASSIFIER`   | Classifica a intenção da mensagem              |
| `AGENT_ENTITY_EXTRACTOR`    | Extrai entidades (datas, nomes, valores)       |
| `AGENT_INTERPRETER`         | Interpreta a ideia do usuário                  |
| `AGENT_CLASSIFIER`          | Decide se vai para n8n ou Python               |
| `AGENT_SELECTOR`            | Escolhe e adapta o workflow n8n                |
| `AGENT_DEVELOPER`           | Gera código Python para automações             |
| `MODEL_TIER_BASIC`          | Modelo usado por usuários do plano Basic       |
| `MODEL_TIER_PRO`            | Modelo usado por usuários do plano Pro         |
| `MODEL_TIER_MAX`            | Modelo usado por usuários do plano Max         |

**Exemplo de valor:**
```env
AGENT_INTENT_CLASSIFIER=gemini|gemini-2.5-flash-lite|https://generativelanguage.googleapis.com/v1beta|GOOGLE_API_KEY
```

### n8n e Webhooks

| Variável                    | Obrigatória | Descrição                              |
| --------------------------- | ----------- | -------------------------------------- |
| `N8N_WEBHOOK_URL`           | Sim         | URL base do n8n                        |
| `N8N_WEBHOOK_SECRET`        | Sim         | Segredo do Header X-N8N-Webhook-Secret |

### Stripe (Billing)

| Variável                    | Obrigatória | Descrição                              |
| --------------------------- | ----------- | -------------------------------------- |
| `STRIPE_SECRET_KEY`         | Sim (SaaS)  | Chave secreta do Stripe                |
| `STRIPE_WEBHOOK_SECRET`     | Sim (SaaS)  | Segredo do Webhook do Stripe           |
| `BASIC_PLAN_ID`             | Sim (SaaS)  | ID do Price do plano Basic no Stripe   |
| `PRO_PLAN_ID`               | Sim (SaaS)  | ID do Price do plano Pro no Stripe     |
| `MAX_PLAN_ID`               | Sim (SaaS)  | ID do Price do plano Max no Stripe     |

### Aplicação

| Variável                    | Obrigatória | Descrição                              |
| --------------------------- | ----------- | -------------------------------------- |
| `ENVIRONMENT`               | Não         | `development` ou `production`          |
| `ENCRYPTION_KEY`            | Sim         | Chave para criptografia interna        |
| `APP_DEEP_LINK_SCHEME`      | Não         | Esquema de deep link (ex: `catas`)     |

### Exemplo .env (Backend)

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
GOOGLE_API_KEY=AIza...

# Créditos (padrão 2000 tokens = 1 crédito)
TOKENS_PER_CREDIT=2000

# Agentes de IA
AGENT_INTENT_CLASSIFIER=gemini|gemini-2.5-flash-lite|https://generativelanguage.googleapis.com/v1beta|GOOGLE_API_KEY
AGENT_INTERPRETER=gemini|gemini-2.5-flash|https://generativelanguage.googleapis.com/v1beta|GOOGLE_API_KEY

# Desenvolvimento local com mock n8n
N8N_WEBHOOK_URL=http://localhost:5678/webhook
N8N_WEBHOOK_SECRET=dev-secret-123

# Stripe (opcional no desenvolvimento)
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
BASIC_PLAN_ID=price_...
PRO_PLAN_ID=price_...
MAX_PLAN_ID=price_...

ENVIRONMENT=development
```

---

## App Flutter (app_flutter/)

Crie um arquivo `.env` na raiz de `app_flutter/` (e `.env.production` para produção):

| Variável              | Obrigatória   | Descrição                                                                  |
| --------------------- | ------------- | -------------------------------------------------------------------------- |
| `SUPABASE_URL`        | Sim           | URL do projeto Supabase                                                    |
| `SUPABASE_ANON_KEY`   | Sim           | Chave anônima do Supabase (pública)                                        |
| `API_BASE_URL`        | Condicional   | URL base da API (ex: `http://10.0.2.2:8000/api/v1` para Android Emulator) |
| `DEMO_MODE`           | Não           | `true` para usar dados mockados (apresentações sem backend)                |
| `WEB_CLIENT_ID`       | Sim (Google)  | Client ID do Google OAuth (Web)                                            |
| `ANDROID_CLIENT_ID`   | Sim (Android) | Client ID do Google OAuth (Android)                                        |
| `IOS_CLIENT_ID`       | Sim (iOS)     | Client ID do Google OAuth (iOS)                                            |
| `CLOUDINARY_CLOUD_NAME` | Não         | Nome do cloud Cloudinary para upload de arquivos                           |

### Exemplo .env (Flutter)

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=eyJ...

# Desenvolvimento
API_BASE_URL=http://10.0.2.2:8000/api/v1
DEMO_MODE=false

# Google OAuth
WEB_CLIENT_ID=xxx.apps.googleusercontent.com
ANDROID_CLIENT_ID=xxx.apps.googleusercontent.com
IOS_CLIENT_ID=xxx.apps.googleusercontent.com
```

### Notas para Dispositivos

- **Android Emulator**: Use `10.0.2.2` em vez de `127.0.0.1` para acessar o localhost do host.
- **iOS Simulator**: Use `127.0.0.1` ou `localhost`.
- **Web**: Use `http://localhost:8000/api/v1` ou a URL do backend em produção.

---

## Mock n8n

Para testes locais sem n8n real, use o `mock_n8n.py`:

```bash
python server/mock_n8n.py
```

Configurar no backend:

```env
N8N_WEBHOOK_URL=http://localhost:5678/webhook
N8N_WEBHOOK_SECRET=dev-secret-123
```

O mock responde em `http://localhost:5678/webhook/chatbot`.
