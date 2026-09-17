# CATAS Architecture

## Overview

CATAS (Context Aware Task Automation System) segue uma abordagem **Headless AI**: o Flutter captura intencao e exibe resultados, enquanto o backend Python processa toda a inteligencia e orquestracao.

## Components

### 1. Frontend (Flutter)

- **Funcao**: Interface de usuario, entrada e saida.
- **Plataformas**: Windows, Web, Android, iOS.
- **Tech**: Flutter (Dart), Material 3, Google Fonts.
- **Telas**:
  - **ChatScreen**: Interface principal de chat.
  - **MainLayout**: Drawer com navegacao, Automacoes, Integracoes, Settings.
  - **LoginScreen**: Login com Google/Email (via Firebase Auth).
  - **AutomationsScreen**: Gerenciamento de automacoes.
  - **IntegrationsScreen**: Gerenciamento de integracoes.
- **Responsabilidade**: Estado do chat, envio de mensagens, renderizacao de Action Cards.

### 2. API Server (Python/Flask)

- **Funcao**: "Cerebro" do sistema.
- **Tech**: Python 3.11+, Flask, SQLAlchemy, Pydantic.
- **Rotas principais**:
  - `POST /api/v1/chat/message` - Chat (Groq + Gemini).
  - CRUD de sessoes e historico em `/api/v1/chat/`.
  - Automacoes, Integracoes, Pagamentos, Webhooks.
- **NLU**: Groq/Gemini classificam intencao e extraem parametros.

### 3. Worker (Python/FastAPI)

- **Funcao**: Motor de execucao de automacoes.
- **Tech**: FastAPI, Python puro.
- **Porta**: 8001
- **Modulos**: Google Calendar, Gmail, Sheets, Drive, Flow Control.

### 4. External Services

- **Supabase**: PostgreSQL (database) + Auth (opcional).
- **Firebase**: Autenticacao (Auth) + Push notifications (FCM).
- **Stripe**: Checkout e assinaturas.
- **Google**: Gemini AI, OAuth para integracoes.
- **Groq**: LLM para pipeline de IA.

---

## Data Flow

1. **Usuario** envia "Agendar reuniao amanha...".
2. **Flutter** faz POST para `/api/v1/chat/message` com `Authorization: Bearer <token>`.
3. **Backend** classifica intencao, extrai entidades, monta payload.
4. **Worker** executa o plano de automacao.
5. **Flutter** exibe resultado na UI.

---

## Architecture Diagram

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

## Documentacao Relacionada

- [Backend](backend.md) - Estrutura detalhada.
- [Integracoes](../referencia/integracoes.md) - Google, Stripe, Supabase.
- [Banco de Dados](banco-dados.md) - Schema e tabelas.
- [Sistema de Creditos](sistema-creditos.md) - Como funcionam os creditos.
