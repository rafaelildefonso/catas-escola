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
  - **LoginScreen**: Login com Google (via Supabase Auth).
  - **AutomationsScreen**, **IntegrationsScreen**, **HistoryScreen**: Placeholders.
- **Responsabilidade**: Estado do chat, envio de mensagens, renderizacao de Action Cards.

### 2. API Server (Python/Flask)

- **Funcao**: "Cerebro" do sistema.
- **Tech**: Python 3.11+, Flask, SQLAlchemy, Pydantic.
- **Rotas principais**:
  - `POST /api/v1/chat/message` - Chat (Groq + Gemini).
  - CRUD de sessoes e historico em `/api/chat/`.
  - Automacoes, Integracoes, Pagamentos, Webhooks.
- **NLU**: Groq/Gemini classificam intencao e extraem parametros.

### 3. Worker (Python/FastAPI)

- **Funcao**: Motor de execucao de automacoes.
- **Tech**: FastAPI, Python puro.
- **Modulos**: Google Calendar, Gmail, Sheets, Drive, Docs, HTTP, AI Transform.

### 4. External Services

- **Supabase**: Autenticacao (Auth) + PostgreSQL via SQLAlchemy.
- **Firebase**: Push notifications (FCM).
- **Stripe**: Checkout e assinaturas.
- **Google**: Gemini AI, OAuth para integracoes.

---

## Data Flow

1. **Usuario** envia "Agendar reuniao amanha...".
2. **Flutter** faz POST para `/api/v1/chat/message` com `Authorization: Bearer <token>`.
3. **Backend** classifica intencao, extrai entidades, monta payload.
4. **Worker** executa o plano de automacao.
5. **Flutter** exibe resultado na UI.

---

## Documentacao Relacionada

- [Backend](backend.md) - Estrutura detalhada.
- [Integracoes](../referencia/integracoes.md) - Google, Stripe, Supabase.
