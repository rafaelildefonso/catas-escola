# Arquitetura de Banco de Dados (SaaS Ready)

Esta documentação descreve a arquitetura de dados consolidada do projeto CATAS, baseada no schema de produção para Supabase. O sistema utiliza `timestamptz` para consistência global e RLS (Row Level Security) para segurança multi-tenant.

## 1. Perfil e Identidade

### `profiles`

Gerencia informações estendidas do usuário e limites de uso.

- `id` (uuid, PK): Referencia `auth.users`.
- `subscription_tier` (text): Nível da assinatura ('free', 'pro', 'max').
- `monthly_quota_limit` (int): Limite mensal de créditos (ex: 50 p/ Free).
- `quota_used` (int): Créditos consumidos no mês atual (1 crédito = 2000 tokens).
- `last_quota_reset` (timestamptz): Data do último reset mensal.
- `customer_id` (text): ID do cliente no Stripe para vinculação de faturamento.
- `created_at` / `updated_at` (timestamptz).

> [!TIP]
> Um trigger automático (`on_auth_user_created`) cria o registro nesta tabela assim que um usuário se cadastra no Supabase Auth.

---

## 2. Chat e Mensagens

### `chat_sessions`

Agrupador de conversas.

- `id` (uuid, PK).
- `user_id` (uuid, FK): Referencia `profiles.id`.
- `title` (text): Título da conversa (default: 'Nova Conversa').
- `created_at` / `updated_at` (timestamptz).

### `messages`

Histórico de mensagens.

- `id` (uuid, PK).
- `session_id` (uuid, FK): Referencia `chat_sessions.id` (CASCADE).
- `role` (text): 'user', 'assistant' ou 'system'.
- `content` (text): Conteúdo da mensagem.
- `metadata` (jsonb): Dados extras (ex: detalhes de ação).
- `created_at` (timestamptz).

---

## 3. Contexto e Navegação

### `browser_sessions`

Rastreia as sessões ativas do usuário na extensão/app.

- `id` (uuid, PK).
- `user_id` (uuid, FK): Referencia `profiles.id`.
- `user_agent` (text): Identificação do navegador.
- `started_at` / `last_activity_at` (timestamptz).

### `page_contexts`

Contexto em tempo real da página visitada.

- `id` (uuid, PK).
- `user_id` (uuid, FK): Referencia `profiles.id`.
- `session_id` (uuid, FK): Referencia `browser_sessions.id`.
- `url` / `domain` (text).
- `page_title` / `html_summary` (text).
- `created_at` (timestamptz).

### `page_analysis_cache`

Cache global de análise de URLs para otimizar chamadas de IA.

- `url_hash` (text, PK).
- `url` (text).
- `analysis_result` (jsonb).
- `expires_at` (timestamptz).

---

## 4. IA e Execução

### `ai_suggestions`

Sugestões proativas baseadas no contexto da página.

- `id` (uuid, PK).
- `user_id` (uuid, FK): Referencia `profiles.id`.
- `context_id` (uuid, FK): Referencia `page_contexts.id`.
- `title` / `description` (text).
- `confidence_score` (float).
- `payload_preview` (jsonb).
- `suggested_workflow` (text): ID ou nome do workflow no n8n.
- `status` (enum): 'pending', 'accepted', 'rejected', 'executed'.

### `automations` (definições)

Plano versionado: gatilho + steps em JSON (fonte de verdade além de `saved_automations` legada).

- `trigger` / `steps` (jsonb), `status` ('draft' | 'active' | 'paused'), `version`, `external_ref` (jsonb).
- Migração copia linhas de `saved_automations` para cá (mesmos `id` quando aplicável).

### `automation_runs`

Uma linha por execução (**Temporal** ou **n8n**).

- `id` (uuid, PK): costuma coincidir com o `automation_id` usado no chat / step logs quando a origem é `execution_logs`.
- `automation_id` (uuid, FK opcional): referência à definição em `automations`.
- `temporal_workflow_id` (text), `correlation_id` (text, único), `run_type` ('temporal' | 'n8n').
- `input_payload` / `result_metadata` / `error_details` / `steps_summary` (jsonb).
- `status`: 'pending', 'running', 'completed', 'failed', 'canceled'.

### `automation_step_logs`

Status em tempo real por step (Realtime no Flutter). Inclui `user_id` e `run_id` (FK para `automation_runs`) para RLS.

### `automation_generation_logs`

Auditoria do Maestro (intent, tentativas, erros, plano final, modelo/tokens). Sem leitura para o cliente anon (apenas service role / API).

### `automation_feedback`

Opt-in: avaliação / labels / payload para dataset de melhoria da IA.

### `execution_logs`

Legado usado pelo chat para correlacionar disparos; `automation_runs` é o histórico canônico de execução.

### `ia_memory`

Memória semântica para RAG (extensão **pgvector**). Busca via função `match_ia_memory`.

- `embedding` (vector(1536), opcional até preenchimento).
- `metadata` (jsonb).

Índice IVFFLAT/HNSW recomendado após carga inicial (ver migração `010_pgvector_ia_memory.sql`).

---

## 5. Integrações & Dispositivos

### `integrations` (equivalente a “user_integrations” na documentação antiga)

Tabela real no Supabase: `integrations`, com `access_token` / `refresh_token` **criptografados no backend** (AES-256-GCM com prefixo `v2:`, com fallback de leitura para tokens **Fernet** legados).

- `user_id` / `provider` (Unique Key).
- `token_expires_at` (timestamptz): usado para refresh lazy (Google).
- `settings` (jsonb).

### `user_devices`

Tokens para notificações via Firebase Cloud Messaging (FCM).

- `id` (uuid, PK).
- `user_id` (uuid, FK): Referencia `profiles.id`.
- `fcm_token` (text): Token único do dispositivo.
- `platform` (text): 'android', 'ios' ou 'web'.
- `last_seen_at` (timestamptz).

### `saved_automations`

Automações favoritas ou customizadas do usuário.

- `name` / `description` (text).
- `workflow_id_n8n` (text).
- `trigger_type` (text): Ex: 'manual', 'domain_filter'.
- `domain_filter` (text).
- `is_active` (boolean).
