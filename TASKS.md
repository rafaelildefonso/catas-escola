# 📋 CATAS - Central de Tarefas (Roadmap Completo SaaS)

**Produto:** CATAS (Context Aware Task Automation System)  
**Visão:** Agente de Automação Inteligente baseado em Linguagem Natural que converte comandos em workflows executados via FastAPI Worker  
**Foco:** Confiabilidade Industrial, Escalabilidade e Monetização SaaS  

> **Arquitetura de Agentes:**
> 1. **Gateway** (Roteador) → 2. **Arquiteto** (Planner) → 3. **Engenheiro** (Coder) → 4. **Q.A.** (Segurança) → 5. **Execução** (Worker) → 6. **Debugger** (Correção) → 7. **Comunicador** (Voz)

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

### Backend Python/Flask
- [x] <~30m> Configurar ambiente Flask + SQLAlchemy + estrutura de pastas
- [x] <~60m> Configurar Supabase Client (auth + database)
- [x] <~60m> Implementar middleware de autenticação JWT
- [x] <~90m> Configurar logging estruturado (JSON) com correlação de request_id
- [x] <~60m> Implementar health check endpoint (`/health`)
- [x] <~60m> Configurar CORS para múltiplos ambientes (dev/staging/prod)
- [x] <~60m> **Rate Limiting:** Implementar rate limiting por plano (Free: 50 req/min, Pro: 200 req/min)
- [x] <~90m> **Segurança:** Implementar proteção contra Prompt Injection (validação de input)
- [ ] <~120m> **Observabilidade:** Integrar Sentry para rastreamento de erros
- [ ] <~60m> **Observabilidade:** Integrar PostHog para analytics de comportamento

### Worker FastAPI Setup
- [x] <~60m> **Setup Worker:** Configurar FastAPI server (port 8001)
- [x] <~60m> **AutomationRunner:** Criar runner para execução de automações
- [x] <~60m> **Module Registry:** Criar catálogo de módulos disponíveis
- [x] <~45m> **Variable Resolver:** Implementar resolução de variáveis `{{step_id.campo}}`
- [x] <~60m> **Retry Policy:** Configurar retry automático (3 tentativas)
- [x] <~90m> **Logging:** Implementar log de cada step no banco

### Flutter App Foundation
- [x] <~60m> Setup Flutter com Material Design 3
- [x] <~60m> Configurar GoRouter para navegação com deep links
- [x] <~45m> Configurar Provider para state management
- [x] <~60m> Configurar Firebase Auth no Flutter
- [x] <~60m> Sistema de idiomas (i18n) completo
- [x] <~60m> Configurar tema claro/escuro
- [x] <~45m> Configurar Firebase (FCM, Analytics, Crashlytics)

---

## 1.2 Database Schema (PostgreSQL)

### Core Tables
- [x] <~60m> Criar schema `profiles` (usuário, quota, assinatura Stripe)
- [x] <~60m> Criar schema `chat_sessions` e `messages` com RLS
- [x] <~30m> Criar tabela `user_devices` (FCM tokens)
- [x] <~60m> Criar tabela `integrations` (tokens OAuth criptografados AES-256)
- [x] <~60m> **Schema de Automações:** Criar tabela `automations` (trigger + steps JSONB + status)
  - [x] Tabela `automation_step_logs` existe (reporta status de cada step)
  - [x] Tabela `automations` completa (definição da automação)
  - [x] Tabela `automation_runs` (histórico por execução)
  - [x] Tabela `automation_feedback` (dataset de melhoria da IA)
- [x] <~60m> **Audit Log:** Criar `automation_generation_logs` (intent, tentativas, erros, plano final)
- [x] <~60m> **Memória Semântica:** Criar `ia_memory` (vector embeddings para RAG)
- [x] <~60m> **RLS Hardening:** Revisar políticas de Row Level Security em TODAS as tabelas

### Índices e Performance
- [x] <~30m> Criar índices para `chat_sessions(user_id)`, `messages(session_id)`
- [x] <~30m> Criar índices para `automation_logs(user_id, status)`
- [x] <~30m> Criar índices GIN para campos JSONB de steps
- [x] <~30m> Configurar `pgvector` extension para embeddings

---

## 1.3 Autenticação Completa

### Flutter
- [x] <~40m> Login com Google via Firebase Auth
- [x] <~60m> Autenticação Apple (Sign in with Apple)
- [x] <~60m> **Login com Email:** Implementar email/password + Magic Link
- [x] <~45m> **Deep Linking:** Configurar `_initDeepLinks()` para OAuth callbacks
- [x] <~60m> **Splash Screen:** Implementar com verificação de servidor, retry e animação
- [x] <~30m> **Onboarding:** Criar 3 telas de onboarding

### Backend
- [x] <~90m> **OAuth Flow:** Implementar callbacks para Google, Slack, Notion, Meta
- [~] <~60m> **Token Management:** Refresh automático **lazy para Google**
- [x] <~60m> **Token Encryption:** AES-256-GCM (prefixo `v2:`) em `crypto.py`

---

# 🤖 FASE 2: AI PIPELINE (O Cérebro Agêntico)

## 2.1 Módulos de IA Implementados

- [x] <~30m> Criar classe `AIService` para integração com providers de IA
- [x] <~60m> Implementar `IntentClassifier` (Gateway/Agêntico Router)
- [x] <~60m> Implementar `EntityExtractor` (extrai entidades)
- [x] <~120m> **Orquestração:** Implementar fluxo Router → Planner → Validator → Retry
- [x] <~120m> **Memória Semântica:** Implementar RAG (Vector DB) para contexto do usuário
- [x] <~90m> **Prompt Builder:** Injetar dinamicamente módulos disponíveis
- [x] <~90m> **AutomationValidator:** Validar module_id, params obrigatórios, tipos
- [x] <~90m> **Retry com Feedback:** Loop de autocorreção (máximo 3 tentativas)
- [x] <~60m> **Self-Healing:** Loop de auto-correção de execuções falhas
- [x] <~60m> **Streaming de Pensamento:** SSE para status em tempo real
- [x] <~60m> **Generation Logger:** Logar intent, tentativas, erros, plano final

## 2.2 Agente 1: Gateway (Roteador)

- [x] <~30m> Classificar intenção: CHAT vs EXECUTE
- [x] <~30m> Prompt otimizado para Groq/Gemini
- [x] <~30m> Retornar JSON: `{"route": "chat" | "automation"}`
- [ ] <~30m> **Context Caching:** Implementar cache do system prompt

## 2.3 Agente 2: Arquiteto (Planner)

- [x] <~60m> Receber intenção + contexto do usuário
- [x] <~60m> Quebrar pedido em passos lógicos
- [x] <~60m> Selecionar módulos do registry filtrados por integrações ativas
- [x] <~60m> Criar DSL (plano de passos) com condicionais e branches
- [ ] <~60m> **Templates de Segmento:** Sugerir templates pré-prontos

## 2.4 Agente 3: Engenheiro (Coder)

- [x] <~60m> Transformar plano em JSON válido
- [x] <~60m> Referenciar apenas `module_id` existentes no registry
- [x] <~30m> Validar sintaxe do JSON gerado
- [ ] <~60m> **Template Resolver:** Substituir variáveis `{{user.email}}` com valores reais

## 2.5 Agente 4: Q.A. (Inspetor de Segurança)

- [x] <~90m> Verificar se module_ids existem no registry
- [x] <~90m> Verificar params obrigatórios e tipos
- [x] <~60m> Verificar se integrações necessárias estão ativas
- [ ] <~60m> **Segurança Avançada:** Detectar tentativas de injection

## 2.6 Agente 5: Execução (Worker FastAPI)

- [x] <~120m> **AutomationRunner:** Runner principal que itera sobre steps
- [x] <~60m> Executar Módulos correspondentes
- [x] <~60m> Retry automático com backoff exponencial
- [x] <~45m> Reportar status ao backend em tempo real
- [x] <~60m> **Variable Resolver:** Injeção de outputs de steps anteriores

## 2.7 Agente 6: Debugger (Corretor)

- [x] <~60m> Analisar erros de módulo falho
- [x] <~60m> Gerar sugestão de correção para o Arquiteto
- [x] <~30m> Limite de 3 tentativas para evitar loops infinitos
- [ ] <~60m> **Fallback:** Retornar templates pré-validados após 3 falhas

## 2.8 Agente 7: Comunicador (A Voz)

- [x] <~60m> Humanizar resultados da automação para o usuário
- [x] <~30m> Usar modelos rápidos para baixa latência
- [ ] <~30m> **Personalização:** Adaptar tom de voz baseado no segmento

---

## 2.9 Module Registry

- [~] <~120m> **Module Registry Central:** Criar catálogo com `module_id`, `input_schema`, `output_schema`, `required_integration`, `examples`
  - [x] Hardcoded no Worker (parcial)
  - [ ] Registry centralizado em banco de dados
  - [ ] API para CRUD de módulos (admin)
  - [ ] Documentação automática do registry

---

# ⚙️ FASE 3: MOTOR DE EXECUÇÃO (Worker FastAPI)

## 3.1 Módulos Implementados

- [x] <~60m> **Gmail:** `gmail.send_email`, `gmail.create_draft`
- [x] <~60m> **Google Calendar:** `google_calendar.create_event`, `google_calendar.check_availability`
- [x] <~60m> **Google Sheets:** `google_sheets.append_row`, `google_sheets.read_range`
- [x] <~60m> **Flow Control:** `flow.wait`, `flow.condition`, `flow.loop`

## 3.2 Módulos Pendentes

- [ ] <~60m> **WhatsApp Business:** `whatsapp.send_message` (dificuldade alta por Meta approval)
- [ ] <~60m> **Meta Ads:** `meta_ads.get_campaign_stats`, `meta_ads.pause_campaign`
- [ ] <~60m> **Notion:** `notion.create_page`, `notion.update_database`
- [ ] <~60m> **Slack:** `slack.send_message`, `slack.send_to_channel`
- [ ] <~60m> **Zap Imóveis:** `zap_imoveis.get_new_leads` (polling/webhook)

## 3.3 Worker Features

- [x] <~120m> **AutomationRunner:** Runner principal implementado
- [x] <~60m> **Retry Policy:** 3 tentativas com backoff exponencial
- [x] <~45m> **Status Sync:** Reportar status a cada step via `automation_step_logs`
- [x] <~60m> **Trigger Manual:** Endpoint `/api/v1/automations/trigger`
  - [x] Endpoint existe
  - [x] Salvar `workflow_id` no banco para tracking
  - [x] Integração completa com Worker
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
- [~] <~60m> **Preview de Automação:** Cards sequenciais mostrando os steps
  - [x] UI de preview existe
  - [~] Integração com backend real
- [~] <~60m> **Feedback de Execução:** Stepper em tempo real
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
- [x] <~45m> **Indicador de Pensamento:** Mostrar passos (Raciocinando→Planejando→Executando)

## 4.4 UX/UI Polish

- [x] <~60m> **Web Sidebar:** Navegação com active state, collapse automático
- [x] <~30m> **Web Responsivo:** Sidebar colapsa em telas < 1200px
- [x] <~45m> **Stripe Web:** Redirect para checkout Stripe
- [x] <~30m> **Hospedagem Web:** Deploy na Vercel
- [ ] <~60m> **Landing Page:** Página de conversão com copy de dor e demo
- [ ] <~60m> **Termos/Privacidade:** Páginas próprias
- [ ] <~45m> **Modo Demo:** Flag para apresentações

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

- [x] <~90m> **Lógica de Créditos:** Cálculo por consumo de tokens (2000 tokens = 1 crédito)
- [x] <~60m> **Débito Automático:** Decrementar créditos ao executar automação
- [x] <~45m> **Quota Cache:** Leitura de quota via cache local
- [x] <~60m> **Rollover:** Acumular créditos não usados (máximo 3x do plano)
- [x] <~60m> **Low Credit Alert:** Aviso ao atingir 20% do limite mensal
- [x] <~60m> **Quota Exceeded:** Bloquear execuções se quota mensal atingida

## 5.2 Monetização Web (Stripe)

- [x] <~45m> **Stripe Checkout:** Webhook para criar/atualizar assinaturas
- [x] <~90m> **Gerenciar Assinatura:** Tela para ver próxima cobrança, atualizar cartão, cancelar
- [x] <~60m> **Faturas:** Histórico de cobranças e invoices
- [ ] <~60m> **Upgrade/Downgrade:** Troca de plano com cálculo de créditos proporcionais

## 5.3 Monetização Mobile (RevenueCat)

- [ ] <~120m> **RevenueCat Integration:** SDK Flutter para assinaturas In-App
- [ ] <~60m> **Apple App Store:** Configurar produtos (Free, Pro, Max)
- [ ] <~60m> **Google Play Store:** Configurar produtos (Free, Pro, Max)
- [ ] <~60m> **Paywalls Contextuais:** Modal de upgrade na hora da "dor"

## 5.4 Gatilhos de Upgrade

- [ ] <~60m> **Limitação Inteligente:**
  - [ ] Free: Automações de 1 step apenas
  - [ ] Pro: Multi-step ilimitado
  - [ ] Max: Agendamentos recorrentes + integrações premium
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
- [ ] <~60m> **Testes de Integração:** Supabase, Worker, OAuth
- [ ] <~90m> **Testes de Módulos:** Cada integração com mocks

## 6.2 Testes Flutter

- [ ] <~60m> **Testes de Widget:** Componentes principais (input, cards, stepper)
- [ ] <~60m> **Testes de Integração:** Fluxo completo (login → chat → automação)
- [ ] <~60m> **Testes de Provider:** ChatProvider, AuthProvider, NavigationProvider

## 6.3 Testes E2E

- [ ] <~120m> **Fluxo Completo:** Input → IA → Plan → Validator → Worker → Módulo → Banco
- [ ] <~90m> **Stress Test:** 100 usuários simultâneos
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
- [ ] <~90m> **Beta Fechada:** TestFlight (iOS) e Internal Track (Android)

## 7.2 Documentação

- [x] <~120m> **Documentação Técnica:** API docs (Swagger/OpenAPI)
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
| **F1: Fundação** | ~98% | 🟢 Sólido - Flask + Worker configurados |
| **F2: AI Pipeline** | ~95% | 🟢 Sólido - Multi-agente funcional |
| **F3: Worker** | ~85% | 🟢 Avançado - Core completo; Google Activities ativos |
| **F4: Flutter** | ~85% | 🟢 Boa base - Screens principais e chat pro |
| **F5: SaaS Business** | ~75% | 🟢 Avançado - Créditos e Stripe solidificados |
| **F6: Testes** | ~30% | 🟡 Em Progresso - CI/CD ativo; falta mais testes |
| **F7: Lançamento** | ~5% | 🔴 Crítico - Apenas preparação inicial |

---

# 🎯 PRÓXIMOS 5 PASSOS CRÍTICOS (Prioridade Founder)

1. **🔴 RevenueCat + Créditos:** Monetização mobile é o que separa app de negócio (F5)
2. **🔴 Testes E2E + Prompt Evaluation:** Validar que IA não alucina antes de abrir para usuários (F6)
3. **🟡 Preview de Automação no Chat:** Aha! com mensagem inicial já no chat (F4)
4. **🟡 Kill Switch / Cost Alert:** Proteção contra loops de custo (F1)
5. **🟡 Meta/Notion/Slack Módulos:** Expandir catálogo de integrações (F3)

---

> **Última Atualização:** Setembro 2026  
> **Próxima Revisão:** Após conclusão das tarefas críticas F5

