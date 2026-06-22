---
trigger: always_on
---

# CATAS (Project Architecture: AI Automation Agent)

## 1. Visão Geral do Projeto Acadêmico & SaaS

**Nome:** CATAS (Context Aware Task Automation System)
**Tipo:** Cross-Platform Mobile/Desktop App (Flutter) + Intelligent Backend (Python).
**Definição Técnica:** Uma interface de chat baseada em Linguagem Natural (NLU) que converte intenções do usuário em planos de automação complexos, orquestrados via **Temporal.io** e validados por IA.

### 🎯 Objetivo do Projeto

Demonstrar a aplicação de **Modelos de Linguagem (LLMs)** como o "Cérebro" de sistemas de automação. Diferente de chatbots tradicionais, o CATAS atua como um "Maestro Agêntico", interpretando comandos, planejando execuções multi-step e acionando APIs externas com resiliência industrial.

### 🔑 Princípios de Arquitetura

1. **Mobile-First & Cross-Platform:** Interface desenvolvida 100% em **Flutter** para rodar em Android, iOS e Desktop.
2. **Backend "Maestro":** Toda a lógica de IA, planejamento de workflows e segurança reside no Backend **Python**.
3. **Execução Resiliente (Temporal.io):** O app não executa ações diretamente. Ele solicita um plano à IA, que é então processado pelo **Temporal** para garantir retentativas automáticas e consistência em caso de falhas de rede ou API.
4. **Hibridismo de Ferramenta:** Utiliza **n8n** para prototipagem rápida de novos conectores e **Temporal.io** para a execução escalável em produção.

---

## 2. Tech Stack (School Compliance & Production)

Este projeto utiliza estritamente tecnologias escaláveis que atendem tanto ao escopo acadêmico quanto ao ambiente de produção.

| Camada              | Tecnologia                      | Função                                                              |
| ------------------- | ------------------------------- | ------------------------------------------------------------------- |
| **Interface (UI)**  | **Flutter (Dart)**              | Aplicativo de Chat (Android/iOS/Web) com Dashboards de Impacto.     |
| **Backend API**     | **Python (FastAPI)**            | API Gateway, Gestão de Sessão, Orquestração de Agentes.             |
| **AI Intelligence** | **Gemini (Basic) / Claude (Pro)** | Router → Planner → Validator → Solver (Arquitetura Maestro).        |
| **Orquestração**    | **Temporal.io**                 | Motor de execução de workflows e atividades com retry automático.   |
| **Banco de Dados**  | **PostgreSQL (Supabase)**       | Histórico de conversas, Memória Semântica (Vector), Logs e Cotas.   |
| **Monitoramento**   | **Sentry / PostHog**            | Rastreamento de erros e analytics de comportamento do usuário.      |

---

## 3. Arquitetura de Dados (Schema Design)

O banco de dados PostgreSQL (gerenciado via Supabase) utiliza uma arquitetura modular para suportar chat, contexto de navegação e automações proativas.

> [!IMPORTANT]
> A documentação detalhada de cada tabela e campo pode ser encontrada em `docs/arquitetura/banco-dados.md`.

### Principais Entidades:

1. **Perfil & Cotas:** `profiles` (Usuário, Quota Mensal, Assinatura Stripe, Créditos).
2. **Chat & Mensagens:** `chat_sessions`, `messages`.
3. **Memória & Contexto:** `ia_memory` (Contexto semântico/RAG), `user_integrations`.
4. **Execução de Automação:** `automation_runs` (Log detalhado de execuções Temporal), `automation_feedback`.
5. **Configurações:** `saved_automations`, `user_devices` (FCM tokens).

---

## 4. API Specification (Python Backend)

O coração do projeto. O Python recebe texto e devolve ação.

### Rotas Principais

#### 1. `POST /api/v1/chat/message`

- **Descrição:** Recebe a mensagem do usuário, processa no Gemini e decide se responde texto ou executa ação. Persiste mensagens e sessões.
- **Input:**

```json
{
  "message": "Marcar dentista amanhã às 14h",
  "conversation_id": "uuid (opcional)",
  "current_page_url": "string (opcional)",
  "current_page_title": "string (opcional)"
}
```

- **Output:**

```json
{
  "id": "uuid_mensagem_assistente",
  "text": "Agendei seu dentista para amanhã às 14h.",
  "isUser": false,
  "actionTriggered": true,
  "actionDetails": { "tool": "google_calendar", "status": "done" },
  "session_id": "uuid"
}
```

#### 2. `GET /api/v1/chat/sessions`

- **Descrição:** Lista todas as sessões de chat do usuário.

#### 3. `GET /api/v1/chat/history/{session_id}`

- **Descrição:** Retorna o histórico completo de uma sessão para renderizar no Flutter.

#### 4. `POST /api/v1/chat/sessions`

- **Descrição:** Cria uma nova sessão manualmente.

---

## 5. Pipeline de IA (Maestro Architecture)

O CATAS utiliza uma arquitetura de pipeline multi-agente para garantir que a IA não apenas "converse", mas "faça" de forma segura e precisa.

1. **Intenção (IntentClassifier):** Identifica se o usuário quer apenas conversar ou realizar uma ação (ex: `Action/Task`).
2. **Memória (IA Memory):** Injeta contexto histórico e preferências salvas (RAG) no prompt.
3. **Planejamento (ComplexPlanner):** A IA atua como um Arquiteto, selecionando módulos do **Module Registry** (ex: `whatsapp.send`, `google_calendar.create`) e organizando-os em um `AutomationPlan`.
4. **Validação (AutomationValidator):** Um agente secundário revisa o plano: "Os IDs dos módulos existem?", "Os tipos de dados estão corretos?".
5. **Auto-Correção (Retry Loop):** Se o validador encontrar erros, o plano volta para o Planner para correção (até 3 tentativas).

---

## 6. Motor de Execução (Temporal.io)

Substitui o n8n no papel de executor de produção para garantir **confiabilidade industrial**.

- **Workflow Principal:** Recebe o `AutomationPlan` final e despacha para Workers Temporal.
- **Atividades (Activities):** Funções Python isoladas para cada integração (Gmail, Sheets, Meta Ads, WhatsApp).
- **Resiliência:** Retry automático com backoff exponencial (5s → 15s → 45s). Estado persistente mesmo se o servidor cair.
- **Streaming:** O app recebe status em tempo real via Server-Sent Events (SSE) ou Supabase Realtime à medida que cada etapa do Temporal é concluída.

---

## 7. Roteiro de Desenvolvimento

### 🎓 Etapa 1: MVP Funcional (Validação Técnica) — ✅ CONCLUÍDA

- [x] Backend FastAPI + Pipeline de IA (Maestro Flow).
- [x] Integração com Temporal.io para orquestração de Workflows.
- [x] App Flutter com login, chat e sistema de anexos.
- [x] Dashboard de Impacto (Horas economizadas / Créditos).
- [x] Suporte multi-idioma e Streaming de Pensamento da IA (SSE).

### 🚀 Etapa 2: MVP SaaS Real (Go-to-Market) — ⏳ EM PROGRESSO

**Fase 1: Monetização e Gestão de Uso**
- [x] Stripe Checkout para planos Basic e Pro na Web.
- [x] Sistema de Créditos (2000 tokens = 1 crédito).
- [ ] Implementar RevenueCat para assinaturas In-App (iOS/Android).

**Fase 2: Expansão do Catálogo**
- [x] Atividades Temporal para Google (Sheets, Calendar, Gmail).
- [ ] Implementar Meta Ads, Notion e Slack.
- [ ] Criar Webhook Receiver universal para gatilhos externos.

**Fase 3: Refinamento e Escala**
- [ ] Mobile: Publicação na Google Play e App Store.
- [ ] Segurança: Hardening de RLS no Supabase e auditoria de segredos.
- [ ] Contexto Nativo: Overlay desktop/mobile para captura automática de tela/URL.

---

## 8. Planos e Assinaturas (SaaS)

| Recurso       | Free           | Pro                | Max                 |
| :------------ | :------------- | :----------------- | :------------------ |
| **Créditos**  | 50 / mês       | Ilimitado*         | Ilimitado*          |
| **Modelo**    | Gemini 1.5 Flash | GPT-4o / Claude 3.5 | O1 / Claude 3 Opus |
| **Histórico** | 30 dias        | Ilimitado          | Ilimitado           |
| **Extra**     | -              | Anexos, Multi-step | API, Custom Modules |

*Sujeito a Fair Use Policy. Créditos calculados por consumo de tokens (2k tokens = 1 credit).

> [!NOTE]
> Detalhamento completo dos planos disponível em `docs/billing/planos.md`.

---

## 9. Variáveis de Ambiente (.env)

**SERVER:**

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
# Decide se vai pra n8n ou Python
AGENT_CLASSIFIER=ai|ai-model|ai-api-url|env-key-ai-api-key
# Escolhe e adapta o fluxo n8n
AGENT_SELECTOR=ai|ai-model|ai-api-url|env-key-ai-api-key
# Escreve o código Python final
AGENT_DEVELOPER=ai|ai-model|ai-api-url|env-key-ai-api-key


# Exemplo de como usar com o Gemini no Interpreter (requer API Key correspondente):
# AGENT_INTERPRETER=gemini|gemini-2.5-flash|https://generativelanguage.googleapis.com/v1beta|GOOGLE_API_KEY


# === N8N ===

# TEST
N8N_WEBHOOK_URL=
N8N_WEBHOOK_SECRET=

# PRODUCTION
# N8N_WEBHOOK_URL=
# N8N_WEBHOOK_SECRET=


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

**APP FLUTTER:**

```env
# === SUPABASE ===
SUPABASE_URL=
SUPABASE_ANON_KEY=

# === TEST ===
DEMO_MODE=true|false

# === API KEYS ===

# === CLOUDINARY ===
CLOUDINARY_CLOUD_NAME=

# === OAUTH GOOGLE (SAAS) ===
WEB_CLIENT_ID =
ANDROID_CLIENT_ID =
IOS_CLIENT_ID =

# === SERVER ===
API_BASE_URL=

```
