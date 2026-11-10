# CATAS (Context Aware Task Automation System)

## Equipe
### 3A1

- Rafael Ildefonso Furtado
- Lucas Salman Resende
- Henrique Santos Tavares
- Miguel Teixeira Valadao
- Lucas Nunes Araujo

Agente de Automação Inteligente baseado em Linguagem Natural que **executa ações** no mundo real através de uma interface de chat multiplataforma.

**Produção:** https://catas-ai.vercel.app | **API:** https://catas-ai.onrender.com/api/v1

---

## Arquitetura

- **Client (Flutter):** Interface multiplataforma (Android, iOS, Web, Desktop)
- **Backend API (Flask):** Processa linguagem natural com IA multi-agente
- **Worker (FastAPI):** Executa automações em background

```
┌─────────────────────────────────────────────────────────────────┐
│                    FRONTEND (Flutter)                           │
│    ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│    │  Chat   │  │Automação│  │Dashboard│  │Configurações│      │
│    └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘        │
└─────────┼────────────┼────────────┼────────────┼───────────────┘
          │            │            │            │
          ▼            ▼            ▼            ▼
┌─────────────────────────────────────────────────────────────────┐
│                BACKEND API (Flask + Gunicorn)                   │
│    ┌───────────────────────────────────────────────────────┐   │
│    │              Route → Controller → Service → Model      │   │
│    └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                WORKER (FastAPI + uvicorn)                       │
│    ┌───────────────────────────────────────────────────────┐   │
│    │           AutomationRunner + Module Registry          │   │
│    └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Camada | Tecnologia | Versão |
|--------|-----------|--------|
| Frontend | Flutter (Dart) - Android, iOS, Web, Desktop | 3.10.8+ |
| Backend | Python 3.11+, Flask + SQLAlchemy | 3.0+ / 2.0+ |
| Worker | Python 3.11+, FastAPI + uvicorn | latest |
| AI | Groq (gpt-oss 20b/120b), Gemini 2.5, OpenAI | multi-provider |
| Database | SQLite | - |
| Auth | Firebase Auth + JWT | - |
| Pagamentos | Stripe (Basic/Pro/Max) | - |
| Container | Docker + Docker Compose | Python 3.11-slim |
| Deploy | Render (Backend) + Vercel (Frontend) | - |
| Linter | Ruff | 0.3.5 |
| Testes | Pytest + pytest-asyncio | 8.1.1 |

---

## Funcionalidades

## Parte 1

### Conta e Perfil
1. O sistema deve permitir ao usuário cadastrar uma conta utilizando e-mail e senha.
2. O sistema deve permitir ao usuário realizar login e autenticação na plataforma.
3. O sistema deve permitir ao usuário gerenciar e editar suas informações de perfil e dados pessoais.

### Chat e IA
4. O sistema deve permitir ao usuário enviar mensagens de texto através da interface principal.
5. O sistema deve permitir ao usuário visualizar o histórico de conversas e chats antigos.
6. O sistema deve permitir ao usuário interagir com um chatbot baseado em IA para tirar dúvidas ou executar comandos.

### Arquivos
7. O sistema deve permitir ao usuário anexar e enviar imagens dentro das conversas ou fluxos.
8. O sistema deve permitir ao usuário anexar e gerenciar documentos nos formatos PDF ou DOCX.

### Integrações
9. O sistema deve permitir ao usuário integrar serviços externos de terceiros à plataforma.
10. O sistema deve permitir ao usuário conectar e sincronizar eventos com o Google Calendar.

## Parte 2

### Automações e Fluxos
11. O sistema deve permitir ao usuário criar e gerenciar agendamentos de tarefas de forma automática.
12. O sistema deve permitir ao usuário enviar e-mails automáticos baseados em gatilhos específicos.
13. O sistema deve permitir ao usuário criar e configurar novas automações personalizadas.
14. O sistema deve permitir ao usuário estruturar fluxos de trabalho (workflows) para automação de tarefas operacionais.
15. O sistema deve permitir ao usuário visualizar uma página com a lista de todas as automações que estão ativas.

### Relatórios e Notificações
16. O sistema deve permitir ao usuário gerar e exportar relatórios automáticos sobre as atividades realizadas.
17. O sistema deve permitir ao usuário receber notificações e alertas sobre o status de suas automações.

### Planos e Créditos
18. O sistema deve permitir ao usuário escolher e gerenciar a assinatura de planos de uso.
19. O sistema deve permitir ao usuário consultar a quantidade e o consumo de créditos disponíveis em sua conta.

### Preferências
20. O sistema deve permitir ao usuário alterar o idioma da interface do aplicativo.

---

## Quick Start

### Pré-requisitos
- Python 3.11+
- Conta Supabase + credenciais de API
- Firebase Auth (para autenticação)
- Stripe (para pagamentos)

### 1. Configurar .env

```bash
cd backend
cp .env.example .env
# Edite com suas credenciais
```

### 2. Rodar a API

```bash
cd backend
python -m venv venv
venv\Scripts\activate
python -m pip install -r requirements.txt
python run.py
```

API: http://localhost:8000 | Health: http://localhost:8000/health

### 3. Rodar o Worker (necessário para automações)

```bash
cd backend
venv\Scripts\activate
python -m worker.entrypoint
```

Worker: http://localhost:8001

### 4. Rodar o agendador (necessário para automações recorrentes)

Em um terceiro terminal, com o ambiente virtual ativado:

```bash
cd backend
venv\Scripts\activate
python -m services.automation.scheduler
```

O agendador verifica execuções vencidas a cada 15 segundos e as envia ao worker. Sem ele, ações manuais funcionam, mas automações diárias ou recorrentes não disparam.

### 5. Rodar o Flutter App

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 52159
```

---

## Estrutura do Projeto

```
CATAS - Escola/
├── backend/                 # API Flask + Worker FastAPI
│   ├── application.py       # create_app(), init_firebase()
│   ├── routes.py            # ~112 endpoints
│   ├── models/              # 18 models SQLAlchemy
│   ├── controllers/         # 24 controllers
│   ├── services/            # 24 pastas, ~120 arquivos
│   ├── repositories/        # 8 repositories
│   ├── core/                # Config, security, OAuth
│   ├── worker/              # FastAPI worker
│   ├── tests/               # 11 arquivos de teste
│   ├── migrations/          # 20+ migrations SQL
│   ├── docker-compose.yml   # Docker config
│   └── Dockerfile           # API container
├── frontend/                # App Flutter (Dart)
│   ├── lib/
│   │   ├── components/      # 44 widgets
│   │   ├── screens/         # 26 telas
│   │   ├── providers/       # 15 providers
│   │   ├── models/          # 6 modelos
│   │   └── data/            # 9 repositories
│   └── test/                # Testes Flutter
├── docs/                    # Documentação Mintlify
├── README.md                # Este arquivo
├── AGENTS.md                # Guia de arquitetura
├── arquitetura.md           # Análise estratégica
├── PROJECT_CONTEXT.md       # Contexto completo
├── TASKS.md                 # Roadmap SaaS
└── RUN_CATAS.md             # Instruções de execução
```

---

## Models (18 Entidades)

| # | Model | Tabela | Descrição |
|---|-------|--------|-----------|
| 1 | **User** | `users` | Usuários e credenciais |
| 2 | **Profile** | `profiles` | Perfil, assinatura, cotas |
| 3 | **ChatSession** | `chat_sessions` | Sessões de chat |
| 4 | **Message** | `messages` | Mensagens do chat |
| 5 | **Automation** | `automations` | Definições de automação |
| 6 | **AutomationRun** | `automation_runs` | Execuções de automação |
| 7 | **AutomationStepLog** | `automation_step_logs` | Logs por passo |
| 8 | **AutomationGenerationLog** | `automation_generation_logs` | Auditoria do planner |
| 9 | **ExecutionLog** | `execution_logs` | Logs legados |
| 10 | **Integration** | `integrations` | Tokens OAuth |
| 11 | **MessageFeedback** | `message_feedback` | Feedback mensagens |
| 12 | **AiSuggestion** | `ai_suggestions` | Sugestões de IA |
| 13 | **PageContext** | `page_contexts` | Contexto de página |
| 14 | **BrowserSession** | `browser_sessions` | Sessões navegador |
| 15 | **PageAnalysisCache** | `page_analysis_cache` | Cache análises |
| 16 | **UserDevice** | `user_devices` | Tokens FCM |
| 17 | **UserWebhookConfig** | `user_webhook_configs` | Config webhooks |
| 18 | **IaMemory** | `ia_memory` | Memória semântica (RAG) |

---

## Rotas da API (~112 Rotas)

### Padrão CRUD (5 endpoints por entidade)

| Método | Endpoint | Função |
|--------|----------|--------|
| GET | `/api/v1/<recursos>` | Listar todos |
| GET | `/api/v1/<recursos>/<id>` | Buscar por ID |
| POST | `/api/v1/<recursos>` | Criar |
| PUT | `/api/v1/<recursos>/<id>` | Atualizar |
| DELETE | `/api/v1/<recursos>/<id>` | Deletar |

### Endpoints Especiais

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/api/v1/auth/signup` | Criar conta |
| POST | `/api/v1/auth/login` | Login |
| POST | `/api/v1/chat/message` | Enviar mensagem |
| GET | `/api/v1/chat/history/<session_id>` | Histórico |
| POST | `/api/v1/automations/trigger` | Disparar automação |
| GET | `/api/v1/relatorios/dashboard` | Dashboard |
| GET | `/api/v1/relatorios/automacoes` | Relatório automações |
| GET | `/api/v1/relatorios/chat` | Relatório chat |
| GET | `/api/v1/relatorios/mensagens/busca` | Busca mensagens |

---

## Arquitetura Backend

O backend segue a arquitetura com camadas bem definidas:

```
HTTP Request → Route → Controller → Service → Repository → Procedure (PostgreSQL)
                                 └─→ Model (db.Model) → CRUD básico
```

| Camada | Responsabilidade |
|--------|-----------------|
| **Route** | Mapeamento URL → endpoint |
| **Controller** | HTTP request/response |
| **Service** | Lógica de negócio, validação |
| **Repository** | Consultas complexas, procedures |
| **Model** | Schema + CRUD básico |

---

## Funcionalidades Avançadas (Relatórios)

| Funcionalidade | Endpoint | Descrição |
|----------------|----------|-----------|
| **Dashboard** | `GET /api/v1/relatorios/dashboard` | Estatísticas gerais |
| **Relatório Automações** | `GET /api/v1/relatorios/automacoes` | Execuções filtradas |
| **Relatório Chat** | `GET /api/v1/relatorios/chat` | Sessões e mensagens |
| **Busca Mensagens** | `GET /api/v1/relatorios/mensagens/busca` | Busca por termo |

### Procedures PostgreSQL

| Procedure | Função |
|-----------|--------|
| `fn_dashboard_estatisticas` | Agregação multi-tabela |
| `fn_relatorio_automacoes` | Filtros dinâmicos e paginação |
| `fn_relatorio_chat` | JOIN sessões × mensagens |
| `fn_buscar_mensagens` | Busca ILIKE com paginação |

---

## Testes

### Backend

```bash
cd backend
python -m pytest tests/ -v
python -m pytest tests/test_all_entities.py -v
python -m pytest tests/test_auth_user.py -v
python -m pytest tests/test_chat_flow.py -v
```

### Frontend

```bash
cd frontend
flutter test
```

---

## Documentação

- [Documentação Completa](./docs/) - Site de documentação Mintlify
- [Guia de Arquitetura](./AGENTS.md) - Para agentes de IA
- [Análise Estratégica](./arquitetura.md) - Build-Time vs Run-Time
- [Contexto do Projeto](./PROJECT_CONTEXT.md) - Visão completa
- [Roadmap SaaS](./TASKS.md) - Tarefas e roadmap
- [Instruções de Execução](./RUN_CATAS.md) - Como rodar

---

## Deploy

### Produção

| Serviço | URL | Stack |
|---------|-----|-------|
| **App** | https://catas-ai.vercel.app | Flutter Web |
| **API** | https://catas-ai.onrender.com/api/v1 | Flask + Gunicorn |
| **Worker** | https://catas-ai.onrender.com | FastAPI |
| **Database** | Supabase | PostgreSQL |
| **Auth** | Firebase | Auth |
| **Pagamentos** | Stripe | Billing |

### CI/CD

- **Lint:** Ruff (Python)
- **Testes:** Pytest
- **Deploy Backend:** Render Deploy Hooks
- **Deploy Frontend:** Vercel

---

## Tecnologias

### Backend
- Flask 3.0+ (API)
- SQLAlchemy 2.0+ (ORM)
- FastAPI (Worker)
- Gunicorn (Server)
- PostgreSQL/SQLite (Database)
- Firebase FCM (Push notification)
- Groq/Gemini/OpenAI (IA)
- Stripe (Pagamentos)
- Docker (Containerização)

### Frontend
- Flutter 3.10.8+ (Framework)
- Provider (State Management)
- GoRouter (Navegação)
- Dio (HTTP)
- Material Design 3 (UI)

### Infra
- Render (Deploy)
- Vercel (Frontend)
- Firebase (Auth + Push)
- Stripe (Pagamentos)

---

## Licença

Projeto acadêmico - CATAS 2026

---

**Última Atualização:** Outubro de 2026
