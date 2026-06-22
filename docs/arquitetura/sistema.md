# CATAS Architecture

## Overview

CATAS (Context Aware Task Automation System) segue uma abordagem **Headless AI**: o Flutter captura intenção e exibe resultados, enquanto o backend Python processa toda a inteligência e orquestração.

## Components

### 1. Frontend (Flutter)

- **Função**: Interface de usuário, entrada e saída.
- **Plataformas**: Windows, Web, Android, iOS.
- **Tech**: Flutter (Dart), Material 3, Google Fonts.
- **Telas**:
  - **ChatScreen**: Interface principal de chat.
  - **MainLayout**: Drawer com navegação, Automações, Integrações, Settings.
  - **LoginScreen**: Login com Google.
  - **AutomationsScreen**, **IntegrationsScreen**, **HistoryScreen**: Placeholders.
- **Responsabilidade**: Estado do chat, envio de mensagens, renderização de Action Cards.

### 2. Backend (Python/FastAPI)

- **Função**: "Cérebro" do sistema.
- **Tech**: Python 3.11+, FastAPI, Pydantic.
- **Rotas principais**:
  - `POST /api/v1/chat/message` — Chat (n8n + Gemini fallback).
  - CRUD de sessões e histórico em `/api/v1/chat/`.
  - `POST /api/v1/execute/action` — Execução de automações.
  - User, Automations, Payments, Webhooks.
- **NLU**: Gemini ou n8n classificam intenção e extraem parâmetros.

### 3. External Tools

- **n8n**: Execução de workflows (webhooks).
- **Supabase**: Banco PostgreSQL e Auth.
- **Stripe**: Checkout e assinaturas.
- **Google Gemini**: IA local (fallback).

## Data Flow

1. **Usuário** envia "Agendar reunião amanhã...".
2. **Flutter** faz POST para `{API}/chat/message` com `Authorization: Bearer <token>`.
3. **Backend** tenta n8n; se falhar, usa Gemini.
4. **Python** retorna JSON:
   ```json
   {
     "text": "Reunião agendada!",
     "actionTriggered": true,
     "actionDetails": { "tool": "google_calendar", ... }
   }
   ```
5. **Flutter** exibe Action Card na UI.

## Documentação Relacionada

- [Backend](backend.md) — Estrutura detalhada.
- [Integrações](../referencia/integracoes.md) — n8n, Stripe, Supabase, Gemini.
