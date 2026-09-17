# Arquitetura do Sistema CATAS

**Data:** Setembro de 2026  
**Foco:** Arquitetura de Produção - Flask + FastAPI Worker + IA Multi-Agente

---

## 1. Visão Geral

O CATAS (Context Aware Task Automation System) é uma plataforma SaaS de automação inteligente que converte comandos em linguagem natural em workflows executáveis. A arquitetura separa claramente as responsabilidades entre:

- **Backend API (Flask):** Gerenciamento de dados, autenticação, pipeline de IA
- **Worker (FastAPI):** Execução de automações em background
- **Frontend (Flutter):** Interface multiplataforma

---

## 2. Diagrama de Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FRONTEND (Flutter)                          │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐              │
│  │  Chat   │  │Automação│  │Dashboard│  │Configurações│            │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘              │
└───────┼────────────┼────────────┼────────────┼────────────────────┘
        │            │            │            │
        ▼            ▼            ▼            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    BACKEND API (Flask + Gunicorn)                   │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Route Layer (routes.py)                  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   Controller Layer (24 controllers)         │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   Service Layer (24 pastas, ~120 arquivos)  │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │   │
│  │  │  Chat   │ │Automacao│ │   IA    │ │  Auth   │          │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘          │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   Repository Layer (8 repositories)         │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   Model Layer (18 models SQLAlchemy)        │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              PostgreSQL (Supabase) / SQLite (dev)           │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTP POST /api/v1/automations/trigger
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    WORKER (FastAPI + uvicorn)                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              AutomationRunner (runner.py)                   │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │   │
│  │  │  Parse  │ │ Variable│ │ Execute │ │  Log    │          │   │
│  │  │  Plan   │ │Resolver │ │ Modules │ │ Results │          │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘          │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   Module Registry (modules/)                │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │   │
│  │  │  Gmail  │ │Calendar │ │ Sheets  │ │  Flow   │          │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘          │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    SERVIÇOS EXTERNOS                                │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐    │
│  │ Google  │ │  Stripe │ │ Firebase│ │  Groq   │ │ Gemini  │    │
│  │  APIs   │ │         │ │  Auth   │ │         │ │         │    │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Componentes Principais

### 3.1 Backend API (Flask)

**Porta:** 8000 (produção via Gunicorn)  
**Framework:** Flask 3.0+  
**ORM:** SQLAlchemy 2.0+

#### Estrutura de Camadas

```
HTTP Request
    ↓
Route (routes.py) - Mapeamento URL → Controller
    ↓
Controller (24 controllers) - HTTP request/response
    ↓
Service (24 pastas, ~120 arquivos) - Lógica de negócio
    ↓
Repository (8 repositories) - Consultas complexas
    ↓
Model (18 models) - Schema + CRUD básico
    ↓
PostgreSQL/SQLite
```

#### Responsabilidades por Camada

| Camada | Responsabilidade | CRUD? |
|--------|-----------------|-------|
| **Route** | Mapeamento URL → endpoint | Não |
| **Controller** | HTTP request/response, validação de input | Não |
| **Service** | Lógica de negócio, validação, regras | Sim |
| **Repository** | Consultas complexas, procedures PostgreSQL | Somente leitura |
| **Model** | Schema de dados + CRUD básico (`salvar`, `atualizar`, `deletar`) | Sim |

### 3.2 Worker (FastAPI)

**Porta:** 8001  
**Framework:** FastAPI  
**Runner:** `AutomationRunner` (runner.py)

O Worker é responsável pela execução de automações em background, separado da API principal para:
- **Isolamento:** Falhas em automações não afetam a API
- **Escalabilidade:** Worker pode escalar independentemente
- **Performance:** Execução assíncrona sem bloquear a API

#### Fluxo de Execução de Automação

```
1. Backend recebe POST /api/v1/automations/trigger
2. Backend envia POST para Worker (WORKER_URL/execute)
3. Worker recebe { automation_id, plan_json }
4. AutomationRunner processa:
   a. Parse do JSON do plano
   b. Variable Resolution (substitui {{step_id.campo}})
   c. Execução sequencial dos módulos
   d. Log de cada step no banco
5. Worker retorna resultado
6. Backend notifica usuário (opcional: push notification)
```

### 3.3 Pipeline de IA (Multi-Agente)

O CATAS utiliza uma arquitetura de pipeline multi-agente onde cada agente tem uma responsabilidade específica:

```
Mensagem do Usuário
    ↓
┌─────────────────────────────────────┐
│  AGENT_INTENT_CLASSIFIER            │
│  (Groq llama-3.1-8b-instant)       │
│  Classifica: CHAT ou ACTION         │
└─────────────────────────────────────┘
    ↓ (se ACTION)
┌─────────────────────────────────────┐
│  AGENT_ENTITY_EXTRACTOR             │
│  (Groq llama-3.1-8b-instant)       │
│  Extrai: nomes, datas, emails       │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  AGENT_INTERPRETER                  │
│  (Groq llama-3.1-8b-instant)       │
│  Interpreta: ideia do usuário       │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  AGENT_SELECTOR                     │
│  (Groq llama-3.1-8b-instant)       │
│  Seleciona: módulos disponíveis     │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  AGENT_DEVELOPER                    │
│  (Groq llama-3.3-70b-versatile)    │
│  Gera: JSON do plano de automação   │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  AutomationValidator                │
│  Valida: module_ids, params, tipos  │
└─────────────────────────────────────┘
    ↓
Plano Válido → Worker para Execução
```

#### Configuração de Modelos (Tiered)

| Modelo | Provider | Uso |
|--------|----------|-----|
| `MODEL_TIER_BASIC` | Groq llama-3.1-8b-instant | Chat básico |
| `MODEL_TIER_PRO` | Gemini 2.5 Flash | Chat intermediário |
| `MODEL_TIER_MAX` | Gemini 2.5 Pro | Chat avançado |

### 3.4 Sistema de Automações

#### Estrutura de um Plano de Automação

```json
{
  "automation_id": "uuid",
  "name": "Enviar email de follow-up",
  "steps": [
    {
      "step_id": "step_1",
      "module_name": "gmail.send_email",
      "params": {
        "to": "{{trigger.email}}",
        "subject": "Follow-up: {{trigger.subject}}",
        "body": "Olá {{trigger.name}}, seguindo nossa conversa..."
      }
    },
    {
      "step_id": "step_2",
      "module_name": "flow.wait",
      "params": {
        "duration": "24h"
      }
    },
    {
      "step_id": "step_3",
      "module_name": "gmail.send_email",
      "params": {
        "to": "{{trigger.email}}",
        "subject": "Lembrete: {{trigger.subject}}",
        "body": "{{step_1.response}}"
      }
    }
  ]
}
```

#### Variable Resolver

O Variable Resolver é responsável por substituir variáveis dinâmicas nos parâmetros dos módulos:

**Sintaxe:** `{{step_id.campo}}`

**Exemplos:**
- `{{trigger.email}}` → Email do evento que disparou a automação
- `{{step_1.response}}` → Resposta do step 1
- `{{user.email}}` → Email do usuário

**Fluxo:**

```
1. Worker recebe plano com variáveis
2. Para cada step:
   a. Extrai params do step
   b. VariableResolver.resolve(params, context)
   c. context[step_id] = resultado da execução
3. Params resolvidos são passados para o módulo
```

#### Module Registry

O Worker mantém um catálogo de módulos disponíveis:

| Módulo | Descrição | Integração |
|--------|-----------|------------|
| `gmail.send_email` | Enviar email | Google OAuth |
| `gmail.create_draft` | Criar rascunho | Google OAuth |
| `google_calendar.create_event` | Criar evento | Google OAuth |
| `google_calendar.check_availability` | Verificar disponibilidade | Google OAuth |
| `google_sheets.append_row` | Adicionar linha | Google OAuth |
| `google_sheets.read_range` | Ler intervalo | Google OAuth |
| `flow.wait` | Aguardar tempo | Nenhuma |
| `flow.condition` | Condicional | Nenhuma |
| `flow.loop` | Loop | Nenhuma |

---

## 4. Banco de Dados

### 4.1 Esquema Principal

O banco utiliza PostgreSQL (Supabase) em produção e SQLite para desenvolvimento/testes.

#### Entidades Principais (18 models)

| Model | Tabela | Descrição |
|-------|--------|-----------|
| **User** | `users` | Usuários e credenciais |
| **Profile** | `profiles` | Perfil, assinatura, cotas |
| **ChatSession** | `chat_sessions` | Sessões de chat |
| **Message** | `messages` | Mensagens do chat |
| **Automation** | `automations` | Definições de automação |
| **AutomationRun** | `automation_runs` | Execuções de automação |
| **AutomationStepLog** | `automation_step_logs` | Logs por passo |
| **AutomationGenerationLog** | `automation_generation_logs` | Auditoria do planner |
| **ExecutionLog** | `execution_logs` | Logs legados |
| **Integration** | `integrations` | Tokens OAuth |
| **MessageFeedback** | `message_feedback` | Feedback mensagens |
| **AiSuggestion** | `ai_suggestions` | Sugestões de IA |
| **PageContext** | `page_contexts` | Contexto de página |
| **BrowserSession** | `browser_sessions` | Sessões navegador |
| **PageAnalysisCache** | `page_analysis_cache` | Cache análises |
| **UserDevice** | `user_devices` | Tokens FCM |
| **UserWebhookConfig** | `user_webhook_configs` | Config webhooks |
| **IaMemory** | `ia_memory` | Memória semântica (RAG) |

### 4.2 Procedures PostgreSQL

Consultas complexas são encapsuladas em procedures:

| Procedure | Função |
|-----------|--------|
| `fn_dashboard_estatisticas` | Estatísticas do dashboard |
| `fn_relatorio_automacoes` | Relatório de automações |
| `fn_relatorio_chat` | Relatório de conversas |
| `fn_buscar_mensagens` | Busca de mensagens |
| `match_ia_memory` | Busca semântica (pgvector) |

### 4.3 Row Level Security (RLS)

Todas as tabelas possuem políticas RLS garantindo que:
- Usuários só veem seus próprios dados
- Operações CRUD são validadas por `user_id`
- Admins têm acesso total (via service role)

---

## 5. Autenticação e Segurança

### 5.1 Fluxo de Autenticação

```
1. Usuário faz login (Google/Email)
2. Firebase Auth valida credenciais
3. Backend recebe token Firebase
4. Backend valida e gera JWT próprio
5. JWT é enviado ao frontend
6. Frontend usa JWT em todas as requisições
```

### 5.2 Segurança

| Componente | Implementação |
|------------|---------------|
| **Senhas** | Firebase Auth (não armazenamos) |
| **Tokens OAuth** | AES-256-GCM (crypto.py) |
| **JWT** | python-jose, expiração 24h |
| **RLS** | Políticas por user_id em todas as tabelas |
| **Rate Limiting** | Free: 50 req/min, Pro: 200 req/min |
| **Input Validation** | Pydantic + sanitização |

---

## 6. Deploy e Infraestrutura

### 6.1 Docker

```yaml
services:
  catas_server:    # API Flask (port 8000)
  catas_worker:    # FastAPI Worker (port 8001)
```

### 6.2 Ambientes

| Ambiente | Stack | URL |
|----------|-------|-----|
| **Produção** | Render + Supabase | https://catas.app |
| **Staging** | Render | https://staging.catas.app |
| **Desenvolvimento** | Local | localhost:8000 |

### 6.3 CI/CD

- **Lint:** Ruff (Python)
- **Testes:** Pytest
- **Deploy:** Render Deploy Hooks
- **Frontend:** Vercel (Flutter Web)

---

## 7. Tecnologias

### Backend

| Componente | Tecnologia | Versão |
|------------|-----------|--------|
| Framework | Flask | 3.0+ |
| ORM | SQLAlchemy | 2.0+ |
| Worker | FastAPI | latest |
| Server | Gunicorn | 21.0+ |
| Database | PostgreSQL (Supabase) | - |
| Auth | Firebase Admin SDK | - |
| IA | Groq, Gemini, OpenAI | - |
| Pagamentos | Stripe | - |
| Container | Docker | Python 3.11-slim |

### Frontend

| Componente | Tecnologia | Versão |
|------------|-----------|--------|
| Framework | Flutter | 3.10.8+ |
| State | Provider | 6.1.5+ |
| Navegação | GoRouter | 15.1.2 |
| HTTP | Dio | 5.9.2 |
| Plataformas | Android, iOS, Web, Windows | - |

---

## 8. Fluxos Principais

### 8.1 Fluxo de Chat

```
1. Usuário envia mensagem
2. Frontend POST /api/v1/chat/message
3. Backend recebe mensagem
4. IntentClassifier classifica (CHAT ou ACTION)
5. Se CHAT:
   a. AIService gera resposta (Gemini/Groq)
   b. Resposta salva em messages
   c. Resposta enviada ao frontend
6. Se ACTION:
   a. Pipeline de IA gera plano
   b. Plano validado
   c. Automação criada e enviada ao Worker
   d. Worker executa em background
   e. Usuário recebe notificação
```

### 8.2 Fluxo de Automação

```
1. Usuário cria automação (ou IA gera)
2. Automação salva em automations
3. Trigger ativado (manual/agendado/webhook)
4. Backend envia POST para Worker
5. Worker:
   a. Parse do plano
   b. Variable Resolution
   c. Execução dos módulos
   d. Log de cada step
   e. Resultado final
6. Worker retorna para Backend
7. Backend salva execution_log
8. Usuário notificado (push notification)
```

### 8.3 Fluxo de Pagamento

```
1. Usuário escolhe plano
2. Frontend redireciona para Stripe Checkout
3. Usuário completa pagamento
4. Stripe envia webhook para Backend
5. Backend atualiza profile (plano, créditos)
6. Usuário notificado
```

---

## 9. Escalabilidade

### 9.1 Estratégias

| Componente | Estratégia |
|------------|-----------|
| **API Flask** | Gunicorn com 4 workers |
| **Worker FastAPI** | Instâncias independentes |
| **Banco de Dados** | Supabase (PostgreSQL gerenciado) |
| **Cache** | SQLite (dev) / Redis (produção futuro) |
| **Frontend** | CDN via Vercel |

### 9.2 Limites Atuais

| Recurso | Limite |
|---------|--------|
| **Usuários simultâneos** | ~100 (plano free Render) |
| **Automações/dia** | ~1000 |
| **Tamanho do plano** | 10 steps máximo |
| **Tempo de execução** | 30s por step |

---

## 10. Roadmap Técnico

### Curto Prazo (1-2 meses)
- [ ] Integrar Redis para cache e filas
- [ ] Adicionar rate limiting avançado
- [ ] Implementar circuit breaker para APIs externas
- [ ] Expandir module registry (Meta Ads, Notion, Slack)

### Médio Prazo (3-6 meses)
- [ ] Migrar para AWS/GCP ( Docker + Kubernetes)
- [ ] Implementar fila de processamento (Celery/Redis)
- [ ] Adicionar monitoramento (Sentry, PostHog)
- [ ] Implementar modos de execução paralela

### Longo Prazo (6-12 meses)
- [ ] Multi-tenant architecture
- [ ] API pública para integrações
- [ ] Marketplace de módulos
- [ ] AI fine-tuning com dados do usuário

---

**Última Atualização:** Setembro de 2026  
**Autor:** Equipe CATAS
