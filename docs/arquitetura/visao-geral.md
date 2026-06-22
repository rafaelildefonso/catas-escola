# CATAS Project Overview

> **Last Updated:** 2026-02-14
> **Status:** Active Development
> **Version:** 0.2.0

## 1. System Architecture

CATAS (Context Aware Task Automation System) é projetado como uma plataforma **Headless AI**: o frontend captura intenção e exibe resultados, enquanto o backend realiza toda a orquestração e processamento de IA.

### Components

#### Frontend (`app_flutter/`)

- **Tecnologia**: Flutter (Dart) para Android, iOS, Windows e Web.
- **Função**: Capturar intenção do usuário (interface de chat) e renderizar respostas acionáveis.
- **Providers**: `AuthProvider` (Google Sign-In + Supabase), `ChatProvider` (mensagens), `ThemeProvider` (tema).
- **Rede**: `ChatRepository` comunica com a API usando `Authorization: Bearer <token>`.

#### Backend (`server/`)

- **Tecnologia**: Python (FastAPI).
- **Função**: Gateway de API, coordenação de agentes e execução de Workflows.
- **Serviços**: Stripe (pagamentos), **Temporal.io** (orquestração), Supabase (banco/auth).

#### Database & Auth

- **Provedor**: Supabase (PostgreSQL).
- **Auth**: Google OAuth 2.0 via `signInWithIdToken` + Apple Login.
- **RAG**: Utiliza extensões de Vector para Busca Semântica em `ia_memory`.

---

## 2. Authentication Flow

1. Usuário clica em "Continue com Google" ou Apple.
2. Plugin `supabase_auth` abre seletor nativo.
3. App obtém credenciais e persiste a sessão no Supabase.
4. Perfil automático gerado via Trigger de Banco.

---

## 3. Chat System & IA (Maestro Architecture)

O chat é a interface principal. É **orientado a planos de automação**, não apenas conversacional.

### Fluxo de Dados

1. **Request**: Flutter envia `POST /api/v1/chat/message`.
2. **Backend Pipeline (Maestro)**:
   - **Router**: Classifica intenção (Conversa vs Ação).
   - **Planner**: Se for ação, gera um `AutomationPlan` usando o Module Registry.
   - **Validator**: Valida o plano para garantir que os módulos e parâmetros estão corretos.
   - **Retry Loop**: Corrige o plano automaticamente se a validação falhar.
3. **Execução (Temporal.io)**: O plano validado é enviado para o Worker Temporal para execução resiliente.
4. **Streaming**: Status em tempo real ("IA está pensando...", "Validando...", "Agendando...") enviado ao Flutter via SSE.
5. **Dashboard**: O Flutter atualiza o impacto (horas economizadas) após cada run concluída.

---

## 4. Directory Structure

| Diretório | Descrição |
|-----------|-----------|
| `app_flutter/` | App Flutter multiplataforma |
| `server/` | Backend Python (FastAPI) |
| `docs/` | Documentação do projeto |

---

## 5. Links para Documentação Detalhada

- [Referência da API](../referencia/api.md)
- [Estrutura do Backend](backend.md)
- [Estrutura do App Flutter](app-flutter.md)
- [Variáveis de Ambiente](../comecando/variaveis-ambiente.md)
- [Integrações](../referencia/integracoes.md)
- [Schema do Banco](banco-dados.md)
- [Como Rodar](../comecando/instalacao.md)
