# 📋 CATAS - Central de Tarefas (Roadmap Completo SaaS)

**Produto:** CATAS (Context Aware Task Automation System)  
**Visão:** Agente de Automação Inteligente baseado em Linguagem Natural que converte comandos em workflows executados via Temporal.io  
**Foco:** Confiabilidade Industrial, Escalabilidade e Monetização SaaS  

> **Arquitetura de Agentes:**
> 1. **Gateway** (Roteador) → 2. **Arquiteto** (Planner) → 3. **Engenheiro** (Coder) → 4. **Q.A.** (Segurança) → 5. **Execução** (Temporal) → 6. **Debugger** (Correção) → 7. **Comunicador** (Voz)

---

## 📋 Legenda de Status

- **[x]** - Concluído (código implementado e testado)
- **[~]** - Em Progresso (parcialmente implementado, em desenvolvimento)
- **[ ]** - Pendente (não iniciado)
- **[~x]** - Quase Concluído (95% pronto, pequenos ajustes pendentes)
- **[?]** - Bloqueado (depende de outra tarefa)

---

# 🎯 FASE 1: FUNDAÇÃO (Infraestrutura & Core)

## 1.1 Infraestrutura Base

### Backend Python/FastAPI
- [x] <~30m> Configurar ambiente FastAPI + Pydantic + estrutura de pastas
- [x] <~60m> Configurar Supabase Client (auth + database)
- [x] <~60m> Implementar middleware de autenticação JWT
- [x] <~90m> Configurar logging estruturado (JSON) com correlação de request_id
- [x] <~60m> Implementar health check endpoint (`/health`)
- [x] <~60m> Configurar CORS para múltiplos ambientes (dev/staging/prod)
- [x] <~60m> **Rate Limiting:** Implementar rate limiting por plano (Free: 50 req/min, Pro: 200 req/min)
- [x] <~90m> **Segurança:** Implementar proteção contra Prompt Injection (validação de input)
- [ ] <~120m> **Observabilidade:** Integrar Sentry para rastreamento de erros
- [ ] <~60m> **Observabilidade:** Integrar PostHog para analytics de comportamento

### Temporal.io Setup
- [x] <~60m> **Setup Temporal:** Configurar Temporal Cloud (free tier) + worker local
- [x] <~60m> **Temporal Service:** Criar `TemporalService` para conexão com client
- [x] <~60m> **Retry Policy:** Configurar retry automático (3 tentativas, backoff 5s→15s→45s)
- [x] <~45m> **Status Sync:** Worker reporta status ao Supabase via `report_status`
- [x] <~60m> **Temporal Schedules:** Configurar Scheduled Workflows para triggers agendados
- [x] <~90m> **Circuit Breaker:** Implementar circuit breaker para APIs externas (falha 5x = pausa) — implementado no retry dinâmico do Temporal Worker

### Flutter App Foundation
- [x] <~60m> Setup Flutter com Material Design 3
- [x] <~60m> Configurar GoRouter para navegação com deep links
- [x] <~45m> Configurar Provider/Riverpod para state management
- [x] <~60m> Configurar Supabase Auth no Flutter
- [x] <~60m> Sistema de idiomas (i18n) completo
- [x] <~60m> Configurar tema claro/escuro
- [x] <~45m> Configurar Firebase (FCM, Analytics, Crashlytics)

---

## 1.2 Database Schema (PostgreSQL/Supabase)

### Core Tables
- [x] <~60m> Criar schema `profiles` (usuário, quota, assinatura Stripe)
- [x] <~60m> Criar schema `chat_sessions` e `messages` com RLS
- [x] <~30m> Criar tabela `user_devices` (FCM tokens)
- [x] <~60m> Criar tabela `user_integrations` (tokens OAuth criptografados AES-256) — **implementado como tabela `integrations`** no Supabase; criptografia no backend (`crypto.py`).
- [x] <~60m> **Schema de Automações:** Criar tabela `automations` (trigger + steps JSONB + status)
  - [x] Tabela `automation_step_logs` existe (reporta status de cada step)
  - [x] Tabela `automations` completa (definição da automação) — migração `009_automation_core_schema.sql`
  - [x] Tabela `automation_runs` (histórico por execução)
  - [x] Tabela `automation_feedback` (dataset de melhoria da IA)
- [x] <~60m> **Audit Log:** Criar `automation_generation_logs` (intent, tentativas, erros, plano final) — migração `009`; escrito via `automation_generation_logs` repository
- [x] <~60m> **Memória Semântica:** Criar `ia_memory` (vector embeddings para RAG) — migração `010_pgvector_ia_memory.sql` + `match_ia_memory`; serviço `ia_memory.py`
- [x] <~60m> **RLS Hardening:** Revisar políticas de Row Level Security em TODAS as tabelas — políticas nas migrações 009/010 + matriz em `server/migrations/RLS_MATRIX.md`

### Índices e Performance
- [x] <~30m> Criar índices para `chat_sessions(user_id)`, `messages(session_id)`
- [x] <~30m> Criar índices para `automation_logs(user_id, status)`
- [x] <~30m> Criar índices GIN para campos JSONB de steps — migração `009` (trigger/steps/planos relevantes)
- [x] <~30m> Configurar `pgvector` extension para embeddings — migração `010` (IVFFLAT/HNSW documentado pós-carga)

---

## 1.3 Autenticação Completa

### Flutter
- [x] <~40m> Login com Google via Supabase Auth
- [x] <~60m> Autenticação Apple (Sign in with Apple)
- [x] <~60m> **Login com Email:** Implementar email/password + Magic Link
  - [x] UI existe em `login_screen.dart`
  - [x] Magic Link via **Supabase Auth** (`signInWithOtp` em `auth_provider.dart`); sem endpoint FastAPI dedicado
  - [~] Testes end-to-end — smoke em `app_flutter/test/smoke_test.dart`; E2E auth completo em CI ainda pendente
- [x] <~45m> **Deep Linking:** Configurar `_initDeepLinks()` para OAuth callbacks (+ tratamento `io.supabase.flutter` em `main.dart`)
- [x] <~60m> **Splash Screen:** Implementar com verificação de servidor, retry e animação fade
- [x] <~30m> **Onboarding:** Criar 3 telas de onboarding ("O que você quer automatizar?") — `onboarding_screen.dart` + rota `/onboarding` + prefs
  - [x] **🎯 CRÍTICO:** Primeira automação no CHAT após onboarding — mensagem automática via `chat_screen.dart` (`onboarding_aha_pending`)
  - [~] Integrar Preview de Automação no chat (não em tela separada) — fluxo dispara pelo chat; UI rica de “preview” do plano pode evoluir

### Backend
- [x] <~90m> **OAuth Flow:** Implementar callbacks para Google, Slack, Notion, Meta
- [~] <~60m> **Token Management:** Refresh automático **lazy para Google** (`oauth_token_service.py` + `integrations.py`); estender Slack/Notion/Meta depois
- [x] <~60m> **Token Encryption:** AES-256-GCM (prefixo `v2:`) em `crypto.py` com fallback de leitura Fernet legado

---

# 🤖 FASE 2: AI PIPELINE (O Cérebro Agêntico)

## 2.1 Módulos de IA Implementados

- [x] <~30m> Criar classe `GeminiService` para integração com Google Gemini
- [x] <~60m> Implementar `IntentClassifier` (Gateway/Agêntico Router)
- [x] <~60m> Implementar `ComplexPlanner` (Arquiteto - gera AutomationPlan)
- [x] <~120m> **Orquestração (The Maestro):** Implementar fluxo Router → Planner → Validator → Retry
- [x] <~120m> **Memória Semântica:** Implementar RAG (Vector DB) para contexto do usuário
- [x] <~90m> **Prompt Builder:** Injetar dinamicamente módulos disponíveis (filtrados por integrações ativas)
- [x] <~120m> **Few-shot por Segmento:** Criar banco de exemplos (corretor, gestor tráfego, advogado)
- [x] <~90m> **AutomationValidator:** Validar module_id, params obrigatórios, tipos, integrações
- [x] <~90m> **Retry com Feedback:** Loop de autocorreção (máximo 3 tentativas)
- [x] <~60m> **Self-Healing:** Loop de auto-correção de execuções falhas no Temporal
- [x] <~60m> **Streaming de Pensamento:** SSE para status em tempo real ("IA pensando...")
- [x] <~60m> **Generation Logger:** Logar intent, tentativas, erros, plano final, segmento

## 2.2 Agente 1: Gateway (Roteador)

- [x] <~30m> Classificar intenção: CHAT vs EXECUTE
- [x] <~30m> Prompt otimizado para Gemini 3 Flash
- [x] <~30m> Retornar JSON: `{"route": "chat" | "automation"}`
- [ ] <~30m> **Context Caching:** Implementar cache do system prompt para economia de tokens

## 2.3 Agente 2: Arquiteto (Planner)

- [x] <~60m> Receber intenção + contexto do usuário
- [x] <~60m> Quebrar pedido em passos lógicos
- [x] <~60m> Selecionar módulos do registry filtrados por integrações ativas
- [x] <~60m> Criar DSL (plano de passos) com condicionais e branches
- [ ] <~60m> **Templates de Segmento:** Sugerir templates pré-prontos baseados no segmento

## 2.4 Agente 3: Engenheiro (Coder)

- [x] <~60m> Transformar plano em AutomationPlan JSON válido
- [x] <~60m> Referenciar apenas `module_id` existentes no registry
- [x] <~30m> Validar sintaxe do JSON gerado
- [ ] <~60m> **Template Resolver:** Substituir variáveis `{{user.email}}` com valores reais

## 2.5 Agente 4: Q.A. (Inspetor de Segurança)

- [x] <~90m> Verificar se module_ids existem no registry
- [x] <~90m> Verificar params obrigatórios e tipos
- [x] <~60m> Verificar se integrações necessárias estão ativas
- [ ] <~60m> **Segurança Avançada:** Detectar tentativas de injection ou operações perigosas

## 2.6 Agente 5: Execução (Temporal Worker)

- [x] <~120m> **AutomationWorkflow:** Workflow principal que itera sobre steps
- [x] <~60m> Executar Activities correspondentes aos módulos
- [x] <~60m> Retry automático com backoff exponencial
- [x] <~45m> Reportar status ao Supabase em tempo real
- [ ] <~60m> **Pass-through de Variáveis:** Injecção de outputs de steps anteriores

## 2.7 Agente 6: Debugger (Corretor)

- [x] <~60m> Analisar erros de Activity falha
- [x] <~60m> Gerar sugestão de correção para o Arquiteto
- [x] <~30m> Limite de 3 tentativas para evitar loops infinitos
- [ ] <~60m> **Fallback:** Retornar templates pré-validados após 3 falhas

## 2.8 Agente 7: Comunicador (A Voz)

- [x] <~60m> Humanizar resultados da automação para o usuário
- [x] <~30m> Usar Gemini 3 Flash para baixa latência
- [ ] <~30m> **Personalização:** Adaptar tom de voz baseado no segmento do usuário

---

## 2.9 Module Registry

- [~] <~120m> **Module Registry Central:** Criar catálogo com `module_id`, `input_schema`, `output_schema`, `required_integration`, `examples`
  - [x] Hardcoded no Pipeline Service (parcial)
  - [ ] Registry centralizado em banco de dados
  - [ ] API para CRUD de módulos (admin)
  - [ ] Documentação automática do registry

---

# ⚙️ FASE 3: MOTOR DE EXECUÇÃO (Temporal.io)

## 3.1 Activities Implementadas

- [x] <~60m> **Gmail:** `gmail.send_email`, `gmail.create_draft`
- [x] <~60m> **Google Calendar:** `google_calendar.create_event`, `google_calendar.check_availability`
- [x] <~60m> **Google Sheets:** `google_sheets.append_row`, `google_sheets.read_range`
- [x] <~60m> **Flow Control:** `flow.wait`, `flow.condition`, `flow.loop`

## 3.2 Activities Pendentes

- [ ] <~60m> **WhatsApp Business:** `whatsapp.send_message` (dificuldade alta por Meta approval)
- [ ] <~60m> **Meta Ads:** `meta_ads.get_campaign_stats`, `meta_ads.pause_campaign`
- [ ] <~60m> **Notion:** `notion.create_page`, `notion.update_database`
- [ ] <~60m> **Slack:** `slack.send_message`, `slack.send_to_channel`
- [ ] <~60m> **Zap Imóveis:** `zap_imoveis.get_new_leads` (polling/webhook)

## 3.3 Workflow Features

- [x] <~120m> **AutomationWorkflow:** Workflow principal implementado
- [x] <~60m> **Retry Policy:** 3 tentativas com backoff exponencial
- [x] <~45m> **Status Sync:** Reportar status a cada step via `automation_step_logs`
- [x] <~60m> **Trigger Manual:** Endpoint `/api/v1/automations/trigger`
  - [x] Endpoint existe
  - [x] Salvar `workflow_id` e `temporal_run_id` no Supabase para tracking
  - [x] Integração completa com Temporal
- [x] <~90m> **Trigger Agendado:** Temporal Schedules para automações recorrentes (CRON)
- [x] <~120m> **Trigger por Evento:** Webhook receiver para eventos externos (Zap Imóveis, Meta) — implementado em `webhooks.py`
- [x] <~60m> **Pause/Resume:** Pausar automação no meio da execução
- [x] <~60m> **Global Error Handler:** Erros reportados ao backend → notificação ao usuário

---

# 📱 FASE 4: FLUTTER APP (Experiência Premium)

## 4.1 Telas Implementadas

- [x] <~60m> **Login/Auth:** Tela de login com Google, Apple, Email
- [x] <~90m> **Dashboard:** Tela de impacto (Créditos Usados, Horas Economizadas)
- [x] <~90m> **Chat Principal:** Input, histórico, anexos, streaming de respostas
- [x] <~60m> **Sessões:** Criar, listar, deletar sessões de chat
- [x] <~60m> **Histórico:** Lista de conversas passadas
- [x] <~60m> **Integrações:** Grid de conectores disponíveis
- [x] <~60m> **Configurações:** Perfil, idioma, tema, notificações
- [x] <~60m> **Planos:** Escolha de plano Free/Pro/Max

## 4.2 Telas de Automação

- [~] <~120m> **Tela de Automações:** Lista com design de fluxo visual
  - [~] Listar automações do usuário
  - [~] Status chips (Ativa, Pausada, Falha)
  - [~] Toggle on/off para cada automação
  - [~] Última execução e contador de runs
- [~] <~90m> **Detalhes da Automação:** Visualização dos steps com ícones
<!-- - [ ] <~60m> **Criação de Automação:** Wizard para criar nova automação -->
- [~] <~60m> **Preview de Automação:** Cards sequenciais mostrando os steps (Step 10)
  - [x] UI de preview existe
  - [~] Integração com backend real
- [~] <~60m> **Feedback de Execução:** Stepper em tempo real (Step 13)
  - [x] Backend pronto
  - [~] UI de stepper real

## 4.3 Chat Features

- [x] <~60m> **Foco Automático:** Input focado ao abrir app
- [x] <~20m> **Shadow no Input:** Sombra no campo de texto
- [x] <~20m> **Botão Enviar:** Ícone branco, tamanho reduzido
- [x] <~60m> **Drop Area Web:** Área de drag-and-drop para arquivos
- [x] <~90m> **Sistema de Anexos:** Upload e gestão de arquivos
- [~] <~60m> **Menções de Integrações:** Sistema de @menções
  - [x] Componente `mention_menu.dart` existe
  - [~] Integração completa com backend
- [ ] <~30m> **Prompts Sugeridos:** Biblioteca de exemplos no input
- [x] <~30m> **Stop Button:** Interromper geração da IA
- [x] <~30m> **Componentes de UI do chat:** Componentes de UI do chat (e bloquear quando estiver gerando ou já interagido)
- [x] <~45m> **Indicador de Pensamento:** Mostrar passos (Raciocinando→Planejando→Executando)

## 4.4 UX/UI Polish

- [x] <~60m> **Web Sidebar:** Navegação com active state, collapse automático
- [x] <~30m> **Web Responsivo:** Sidebar colapsa em telas < 1200px
- [x] <~45m> **Stripe Web:** Redirect para checkout Stripe
- [x] <~30m> **Hospedagem Web:** Deploy na Vercel
- [ ] <~60m> **Landing Page:** Página de conversão com copy de dor e demo
- [ ] <~60m> **Termos/Privacidade:** Páginas próprias (não redirecionar externo)
- [ ] <~45m> **Modo Demo:** Flag para apresentações (planos pré-gerados, execução simulada)

## 4.5 Notificações

- [~] <~60m> **Push Notification (FCM):** Avisos de "Automação Concluída ✓"
  - [x] `NotificationsProvider` existe
  - [ ] Testes em produção
  - [ ] Deep link para histórico da run
- [ ] <~60m> **Weekly Digest:** Notificação semanal com estatísticas
- [ ] <~45m> **FCM Token Refresh:** Atualizar token no login/logout

---

# 💰 FASE 5: SAAS BUSINESS LOGIC

## 5.1 Sistema de Créditos

- [x] <~90m> **Lógica de Créditos:** Cálculo por consumo de tokens (2000 tokens = 1 crédito) em `CreditService`
- [x] <~60m> **Débito Automático:** Decrementar créditos ao executar automação via RPC atômico
- [x] <~45m> **Quota Cache:** Leitura de quota via cache local
- [x] <~60m> **Rollover:** Acumular créditos não usados (máximo 3x do plano) — logic in `CreditService`
- [x] <~60m> **Low Credit Alert:** Aviso ao atingir 20% do limite mensal
- [x] <~60m> **Quota Exceeded:** Bloquear execuções se quota mensal atingida (RPC handle_credit_debit)

## 5.2 Monetização Web (Stripe)

- [x] <~45m> **Stripe Checkout:** Webhook para criar/atualizar assinaturas
- [x] <~90m> **Gerenciar Assinatura:** Tela para ver próxima cobrança, atualizar cartão, cancelar (via Stripe Portal)
- [x] <~60m> **Faturas:** Histórico de cobranças e invoices (via Stripe Portal)
- [ ] <~60m> **Upgrade/Downgrade:** Troca de plano com cálculo de créditos proporcionais

## 5.3 Monetização Mobile (RevenueCat)

- [ ] <~120m> **RevenueCat Integration:** SDK Flutter para assinaturas In-App
- [ ] <~60m> **Apple App Store:** Configurar produtos (Free, Pro, Max)
- [ ] <~60m> **Google Play Store:** Configurar produtos (Free, Pro, Max)
- [ ] <~60m> **Paywalls Contextuais:** Modal de upgrade na hora da "dor"
  - [ ] Ao tentar criar 4ª automação (Free limit)
  - [ ] Ao tentar usar módulo de plano superior
  - [ ] Áudios longos (>5 min) no plano Free

## 5.4 Gatilhos de Upgrade

- [ ] <~60m> **Limitação Inteligente:**
  - [ ] Free: Automações de 1 step apenas
  - [ ] Pro: Multi-step ilimitado
  - [ ] Max: Agendamentos recorrentes + integrações premium (WhatsApp)
- [ ] <~60m> **Referral Loop:** "Convide e Ganhe +10 execuções/mês"
- [ ] <~30m> **Copy de Dor:** "Você perdeu quantos leads hoje?"

## 5.5 Feedback Loop

- [ ] <~60m> **Sistema de Feedback:** Botões 👍 👎 em cada automação gerada
- [ ] <~60m> **Dataset de Melhoria:** Salvar feedback em `automation_feedback`
- [ ] <~60m> **Retreinamento:** Usar dataset para melhorar prompts mensalmente

---

# 🧪 FASE 6: TESTES & QUALIDADE

## 6.1 Testes Backend

- [ ] <~90m> **Testes de Pipeline IA:**
  - [ ] Classificação de intenção (50 casos por segmento)
  - [ ] Extração de entidades (datas, emails, valores)
  - [ ] Taxa de sucesso do Validator (meta: >95%)
- [ ] <~60m> **Testes de API:** Rotas de chat, sessões, automações
- [ ] <~60m> **Testes de Integração:** Supabase, Temporal, OAuth
- [ ] <~90m> **Testes de Activities:** Cada integração com mocks

## 6.2 Testes Flutter

- [ ] <~60m> **Testes de Widget:** Componentes principais (input, cards, stepper)
- [ ] <~60m> **Testes de Integração:** Fluxo completo (login → chat → automação)
- [ ] <~60m> **Testes de Provider:** ChatProvider, AuthProvider, NavigationProvider

## 6.3 Testes E2E

- [ ] <~120m> **Fluxo Completo:** Input → Gemini → Plan → Validator → Temporal → Activity → Supabase → Push
- [ ] <~90m> **Stress Test:** 100 usuários simultâneos, loops de agentes
- [ ] <~60m> **Budget Cap:** Limites de tokens e execuções simultâneas
- [ ] <~45m> **Modo Demo:** Validação de execução simulada

## 6.4 CI/CD

- [x] <~60m> **CI/CD Backend:** Deploy automático no Render
- [x] <~60m> **CI/CD Flutter Web:** Deploy automático na Vercel
- [ ] <~90m> **CI/CD Mobile:** Build e upload para App Store/Play Store

---

# 🚀 FASE 7: LANÇAMENTO (Go-to-Market)

## 7.1 Preparação Mobile

- [ ] <~60m> **App Store Connect:** Criar app, configurar metadata
- [ ] <~60m> **Google Play Console:** Criar app, configurar listing
- [ ] <~60m> **Screenshots:** Gerar screenshots para todas as plataformas
- [ ] <~60m> **App Preview:** Vídeo demonstrativo do app
- [ ] <~90m> **Beta Fechada:** TestFlight (iOS) e Internal Track (Android) com 20 usuários

## 7.2 Documentação

- [ ] <~120m> **Documentação Técnica:** API docs (Swagger/OpenAPI)
- [ ] <~60m> **Guia do Usuário:** Como criar automações, templates
- [ ] <~60m> **Guia de Integração:** Como conectar cada serviço (OAuth)
- [ ] <~60m> **Changelog:** Histórico de versões

## 7.3 Marketing

- [ ] <~60m> **Landing Page:** Copy de conversão + formulário de waitlist
- [ ] <~30m> **Vídeo Demo:** Demonstração do "Aha! Moment"
- [ ] <~60m> **Materiais de Apoio:** Pitch deck, one-pager
- [ ] <~30m> **Redes Sociais:** Setup de perfis (LinkedIn, Twitter)

---

# 📊 RESUMO DE STATUS POR FASE

| Fase | Progresso | Status |
|------|-----------|--------|
| **F1: Fundação** | ~98% | 🟢 Schedules + webhooks feitos; falta observabilidade PostHog/Sentry |
| **F2: AI Pipeline** | ~95% | 🟢 Sólido - Orquestração e créditos integrados; faltam refinamentos de voz |
| **F3: Temporal** | ~85% | 🟢 Avançado - Core completo; Google Activities e Webhooks ativos |
| **F4: Flutter** | ~85% | 🟢 Boa base - Screens principais e chat pro; menções em refinamento |
| **F5: SaaS Business** | ~75% | 🟢 Avançado - Créditos e Stripe solidificados; falta RevenueCat |
| **F6: Testes** | ~30% | 🟡 Em Progresso - CI/CD ativo; RLS validado; falta Prompt Eval |
| **F7: Lançamento** | ~5% | 🔴 Crítico - Apenas preparação inicial |

---

# 🎯 PRÓXIMOS 5 PASSOS CRÍTICOS (Prioridade Founder)

1. **🔴 RevenueCat + Créditos:** Monetização mobile é o que separa app de negócio (F5)
2. **🔴 Testes E2E + Prompt Evaluation:** Validar que IA não alucina antes de abrir para usuários (F6)
3. **🟡 Preview de Automação no Chat:** Aha! com mensagem inicial já no chat; enriquecer UI de preview do plano nas mensagens (F4)
4. **🟡 Kill Switch / Cost Alert:** Proteção contra loops de custo (F1)
5. **🟡 Meta/Notion/Slack Activities:** Expandir catálogo de integrações (F3)

---

> **Última Atualização:** 2026-04-28  
> **Próxima Revisão:** Após conclusão das tarefas críticas F5

## 🐍 Server (Flask / Backend de Escala)

- [x] <~30m> Configurar ambiente FastAPI + Pydantic.
- [x] <~60m> Implementar rotas de Chat: `/api/v1/chat/message`, `/sessions`, `/history`.
- [x] <~90m> **OAuth Flow:** Implementar lógica de callback para autenticação de terceiros (Google, Slack, Notion, Meta). Tokens criptografados no Supabase.
- [x] <~90m> **Gerenciamento de Segredos (Vault):** Implementar criptografia AES-256 para salvar chaves de API (Notion, Slack, WhatsApp) dos usuários no Supabase.
- [x] <~60m> **Criar CI/CD:** Criar CI/CD para deploy automático no Render (Configurado GitHub Actions CI com Ruff/Pytest e CD via Render Deploy Hooks, infra separada API/Worker).
- [x] <~60m> **Segurança Avançada:** Proteção contra Prompt Injection (validar que input do usuário não manipula system prompt) e Rate Limiting por plano (Free: 50 exec/mês, Pro: ilimitado).

- [ ] <~120m> **Fila de Processamento (Worker):** Integrar Redis/Celery para tarefas longas fora do Temporal (ex: processamento de arquivos, geração de relatórios).
- [ ] <~45m> **Observabilidade:** Integrar LangSmith ou Helicone para monitorar custos de tokens e latência dos agentes por usuário/segmento.
- [ ] <~60m> **🚨 Kill Switch / Cost Alert:** Alerta automático se custo de IA exceder limite (ex: R$ 50/hour) - enviar notificação ao admin
- [ ] <~120m> **Deploy Pro:** Migrar para AWS ou Google Cloud com Docker e CI/CD configurado.

---

## 📱 App (Flutter - Experiência Premium)

_Status: UI Base Pronta | Foco: UX de Confiança_

- [x] <~60m> Layout base com Material Design 3.
- [x] <~40m> Login com Google via Supabase Auth.
- [x] <~90m> **Dashboard de Impacto:** Tela mostrando "Créditos Usados" e "Horas Economizadas" (Gatilho de Retenção).
- [x] <~30m> **Hospedagem web:** hospedar site web na Vercel.
- [x] <~45m> **Stripe web:** no web, usar redirect para link da Stripe.
- [x] <~15m> **Adicionar anexos:** atualizar para options balloon.
- [x] <~15m> **Web: Enter para enviar.**
- [x] <~60m> **Web - Sistema de rotas:** Implementar GoRouter para URLs amigáveis.
- [x] <~60m> **Integrações ativas no chat:** Painel para gerenciar conectores ativos na sessão atual.
- [x] <~30m> **Atualização de plano:** adicionar "free" no BD por default ao criar conta. Atualizar telas que exibem BASIC para vazio.
- [x] <~90m> **Sistema de anexos:** Sistema robusto de upload e gestão de arquivos.
- [x] <~45m> **Refinamentos de UI/UX (Sprint Atual):**
  - [x] **Input & Chat:**
    - [x] <~15m> Garantir foco automático no input ao iniciar o app.
    - [x] <~20m> Adicionar sombra (shadow) no campo de input.
    - [x] <~20m> Diminuir botão "Enviar" e ícone 100% branco.
    - [x] <~60m> Implementar Drop Area para arquivos na versão Web.

- [x] <~60m> **Autenticação Apple:** Implementar Sign in with Apple.
- [x] <~45m> **Quota Cache:** Implementar leitura de quota de plano via cache local (lido do Supabase periodicamente) (Step 03).
- [x] <~60m> **Sistema de idiomas:** Implementar sistema de idiomas.
- [x] <~30m> **Reverter alterações de bottomsheet:** Bottom Sheets do chat viraram options.
- [x] <~60m> **Tornar páginas reais:** Página gerenciar assinatura e configurações da conta.
- [x] <~45m> **Deep Linking:** Configurar app para abrir automaticamente após OAuth de integrações no navegador. (Implementado via _initDeepLinks em main.dart)
- [x] <~60m> **Splash screen:** Implementar splash screen. (Completo com verificação de servidor, retry e animação)

- [~] <~60m> **Feedback de Execução:** Stepper mostrando qual step está sendo executado pelo Temporal em tempo real. Dados via Supabase Realtime WebSocket (Step 13). (Backend pronto, UI em desenvolvimento)
- [x] <~60m> **Login com email:** Email/senha + Magic Link em `login_screen.dart` / `auth_provider.dart`
- [~x] <~60m> **Páginas de informações:** Página de termos e condições, política de privacidade e sobre. (Links para site externo configurados)
- [~] <~60m> **Push Notification (FCM):** Avisos de "Automação Concluída ✓" com deep link para histórico da run (Step 19). (NotificationsProvider funcional, testes em prod necessários)
- [~x] <~60m> **Sistema de menções de integrações:** Implementar sistema de menções de integrações. (Componente mention_menu.dart integrado ao chat, lógica funcional)

- [~] <~120m> **Tela de Automações:** Tela de detalhes com design de fluxo visual — lista de steps com ícone por módulo, status de última execução, histórico.

- [ ] <~60m> **Sistema de feedback:** Implementar sistema de feedback.
- [ ] <~30m> **Prompts sugeridos:** Adicionar biblioteca de prompts sugeridos.
- [ ] <~60m> **Hospedagem app mobile:** publicar na Play Store.

---

## 🗄️ Database, Security & SaaS (Business Logic)

_Status: Implementando Camada de Cobrança_

- [x] <~60m> Criar schema para `profiles`, `chat_sessions` e `messages`.
- [x] <~30m> **FCM Devices:** Criar tabela `user_devices` para FCM tokens. Salvar no login, refresh via `onTokenRefresh`, deletar no logout. (Migração existe: 20260330_create_user_devices.sql)

- [x] <~60m> **Schema de Automações:** Migrações `009` + `010`: `automations`, `automation_runs`, `automation_feedback`, `automation_generation_logs`, `ia_memory`, evolução `automation_step_logs`. Tabela real de OAuth: `integrations`.

- [x] <~90m> **Sistema de Créditos:** Lógica de débitos por execução por plano. Free: 50 exec/mês. Pro: ilimitado. (Implementado via `CreditService` e RPC `handle_credit_debit`)
- [ ] <~60m> **SaaS Quotas:** Triggers no Supabase para bloquear execuções se quota mensal atingida. Notificar usuário com CTA de upgrade.
- [x] <~60m> **Audit Log:** Tabela `automation_generation_logs` + gravação a partir do `chatbot.py`.
- [x] <~60m> **RLS Hardening:** Políticas nas novas tabelas + `RLS_MATRIX.md`; revisão completa concluída.

---

## 🔗 Integrações (Module Registry — Activities Temporal)

_Status: Concluído | Migrado 100% para Temporal/Python (n8n removido)_

> Cada integração abaixo corresponde a um ou mais módulos no registry e uma Activity no Temporal.

- [nem fodendo] <~60m> **WhatsApp Business:** Activity `whatsapp.send_message`. Params: `to`, `message` com suporte a `{{variáveis}}`.

- [x] <~60m> **Google Calendar:** Activities `google_calendar.create_event`, `google_calendar.check_availability`. OAuth obrigatório.
- [x] <~60m> **Google Sheets:** Activity `google_sheets.append_row`, `google_sheets.read_range`. Relatórios automáticos.
- [x] <~60m> **Gmail:** Activity `gmail.create_draft`, `gmail.send_email`. Briefings e follow-ups.
- [x] <~60m> **Flow Control:** Módulos nativos sem integração externa — `flow.wait`, `flow.condition`, `flow.loop`. Lógica de ramificação entre steps.
- [x] <~30m> **Documentação do Registry:** Mapear todos os `module_id`, schemas de input/output e exemplos de uso. Base para o prompt da IA.

- [ ] <~60m> **Meta Ads:** Activity `meta_ads.get_campaign_stats`, `meta_ads.pause_campaign`. Para gestores de tráfego.
- [ ] <~60m> **Notion:** Activity `notion.create_page`, `notion.update_database`. Task manager.
- [ ] <~60m> **Slack:** Activity `slack.send_message`. Notificações internas.
- [ ] <~60m> **Zap Imóveis:** Activity `zap_imoveis.get_new_leads` (polling). Trigger principal para corretores.
- [x] <~60m> **Token Management:** Refresh lazy **Google** no backend; demais provedores pendentes.
- [x] <~60m> **Global Error Handler:** Erros de Activity reportados ao backend → notificação ao usuário + log em `automation_runs`.

---

## 🚀 Growth & Monetização (Go-to-Market)

_Status: Planejamento de Lançamento_

- [ ] <~120m> **Monetização:** Integrar RevenueCat para assinaturas Apple/Google e Stripe para Web.
- [ ] <~60m> **Gatilhos de Upgrade Contextuais:** Modal ao tentar criar 4ª automação (Free limit), ao atingir 80% das execuções mensais, ao tentar usar módulo de plano superior.
- [ ] <~60m> **Referral Loop:** "Convide e Ganhe +10 execuções/mês". Usuário Pro convida → desconto na próxima mensalidade.
- [~] <~90m> **Onboarding:** Walkthrough 3 telas + primeira mensagem no chat (`onboarding_screen` / prefs); medir tempo até primeira automação e refinar copy/UX em produção.
- [ ] <~60m> **Weekly Digest (Push):** Notificação semanal — "Sua automação rodou 12x essa semana e enviou 12 mensagens por você." Quantifica valor entregue.
- [ ] <~120m> **Landing Page:** Página focada em conversão com copy de dor ("Você perdeu quantos leads hoje?"), vídeo demo e depoimentos.

---

## 🧪 Qualidade & Resiliência

_Status: Pendente_

- [ ] <~90m> **Stress Test:** Simular loops de agentes e execuções paralelas. Definir Budget Cap de tokens e execuções simultâneas por usuário.
- [ ] <~120m> **Testes E2E:** Validar fluxo completo: Input → Gemini → AutomationPlan → Validator → Temporal → Activity → Supabase → Push.
- [ ] <~45m> **Modo Demo:** Flag para apresentações — planos pré-gerados, execução simulada, sem custo real de API.
- [ ] <~60m> **🧪 Testes de Geração IA (Prompt Evaluation):** Script que roda 50 intents de cada segmento e mede taxa de sucesso do AutomationValidator. Meta: >95%.
  - [ ] Detectar se Intent Classifier erra e manda CHAT para Planner (loop prevention)
  - [ ] Testar cenários de alucinação da IA
