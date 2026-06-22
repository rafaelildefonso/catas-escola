-- =========================================================
-- CATAS - SCHEMA PRODUÇÃO SAAS (SUPABASE)
-- =========================================================


-- ---------------------------------------------------------
-- EXTENSÕES
-- ---------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ---------------------------------------------------------
-- ENUMS
-- ---------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE public.ai_suggestion_status AS ENUM
  ('pending','accepted','rejected','executed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.execution_status AS ENUM
  ('running','success','failed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ---------------------------------------------------------
-- PERFIL
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  subscription_tier text DEFAULT 'basic',
  monthly_quota_limit integer DEFAULT 500,
  quota_used integer DEFAULT 0,
  last_quota_reset timestamptz DEFAULT now(),
  language text DEFAULT 'en',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);


-- ---------------------------------------------------------
-- CHAT
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chat_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title text DEFAULT 'Nova Conversa',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid REFERENCES public.chat_sessions ON DELETE CASCADE,
  role text CHECK (role IN ('user','assistant','system')),
  content text NOT NULL,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);


-- ---------------------------------------------------------
-- CONTEXTO
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.browser_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles ON DELETE CASCADE,
  user_agent text,
  started_at timestamptz DEFAULT now(),
  last_activity_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.page_contexts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles ON DELETE CASCADE,
  session_id uuid REFERENCES public.browser_sessions ON DELETE SET NULL,
  url text NOT NULL,
  domain text NOT NULL,
  page_title text,
  html_summary text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.page_analysis_cache (
  url_hash text PRIMARY KEY,
  url text NOT NULL,
  analysis_result jsonb NOT NULL,
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz NOT NULL
);


-- ---------------------------------------------------------
-- IA
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ai_suggestions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles ON DELETE CASCADE,
  context_id uuid REFERENCES public.page_contexts ON DELETE SET NULL,
  title text NOT NULL,
  description text,
  confidence_score float,
  payload_preview jsonb,
  suggested_workflow text,
  status public.ai_suggestion_status DEFAULT 'pending',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.execution_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles ON DELETE CASCADE,
  suggestion_id uuid REFERENCES public.ai_suggestions ON DELETE SET NULL,
  session_id uuid REFERENCES public.chat_sessions ON DELETE SET NULL,
  workflow_name text,
  status public.execution_status DEFAULT 'running',
  input_data jsonb,
  result_data jsonb,
  error_message text,
  started_at timestamptz DEFAULT now(),
  finished_at timestamptz
);


-- ---------------------------------------------------------
-- AUTOMAÇÕES / INTEGRAÇÕES
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.integrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles ON DELETE CASCADE,
  provider text NOT NULL,
  is_connected boolean DEFAULT false,
  access_token text,
  refresh_token text,
  token_expires_at timestamptz,
  settings jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, provider)
);

CREATE TABLE IF NOT EXISTS public.saved_automations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles ON DELETE CASCADE,
  name text,
  description text,
  workflow_id_n8n text,
  trigger_type text DEFAULT 'manual',
  domain_filter text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.usage_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles ON DELETE CASCADE,
  event_type text,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);


-- ---------------------------------------------------------
-- ÍNDICES
-- ---------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_messages_session ON public.messages(session_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON public.chat_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_exec_user ON public.execution_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_integrations_user ON public.integrations(user_id);
CREATE INDEX IF NOT EXISTS idx_cache_exp ON public.page_analysis_cache(expires_at);


-- ---------------------------------------------------------
-- AUTO UPDATED_AT
-- ---------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_profiles_modtime ON public.profiles;
CREATE TRIGGER update_profiles_modtime
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_chat_sessions_modtime ON public.chat_sessions;
CREATE TRIGGER update_chat_sessions_modtime
BEFORE UPDATE ON public.chat_sessions
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_integrations_modtime ON public.integrations;
CREATE TRIGGER update_integrations_modtime
BEFORE UPDATE ON public.integrations
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_saved_automations_modtime ON public.saved_automations;
CREATE TRIGGER update_saved_automations_modtime
BEFORE UPDATE ON public.saved_automations
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


-- ---------------------------------------------------------
-- AUTO CRIAR PROFILE AO REGISTRAR
-- ---------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_language text;
BEGIN
  -- Detect language from user metadata or default to 'en'
  user_language := COALESCE(
    (NEW.raw_user_meta_data->>'language')::text,
    (NEW.raw_user_meta_data->>'locale')::text,
    'en'
  );
  
  -- Map common locale codes to our supported languages
  IF user_language LIKE 'pt%' OR user_language LIKE 'pt-%' THEN
    user_language := 'pt';
  ELSIF user_language LIKE 'en%' OR user_language LIKE 'en-%' THEN
    user_language := 'en';
  ELSE
    -- Default to English for unsupported languages
    user_language := 'en';
  END IF;
  
  INSERT INTO public.profiles (id, language)
  VALUES (NEW.id, user_language);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ---------------------------------------------------------
-- RLS GLOBAL
-- ---------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.browser_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.page_contexts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.page_analysis_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.execution_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_automations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_events ENABLE ROW LEVEL SECURITY;


-- ---------------------------------------------------------
-- POLICIES
-- ---------------------------------------------------------

-- PROFILE
DROP POLICY IF EXISTS "profile_select" ON public.profiles;
CREATE POLICY "profile_select"
ON public.profiles FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "profile_update" ON public.profiles;
CREATE POLICY "profile_update"
ON public.profiles FOR UPDATE USING (auth.uid() = id);


-- CHAT SESSIONS
DROP POLICY IF EXISTS "chat_manage" ON public.chat_sessions;
CREATE POLICY "chat_manage"
ON public.chat_sessions FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);


-- MESSAGES
DROP POLICY IF EXISTS "messages_manage" ON public.messages;
CREATE POLICY "messages_manage"
ON public.messages FOR ALL
USING (
  session_id IN (
    SELECT id FROM public.chat_sessions WHERE user_id = auth.uid()
  )
);


-- CONTEXTOS
DROP POLICY IF EXISTS "browser_manage" ON public.browser_sessions;
CREATE POLICY "browser_manage"
ON public.browser_sessions FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "context_manage" ON public.page_contexts;
CREATE POLICY "context_manage"
ON public.page_contexts FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);


-- CACHE GLOBAL READ
DROP POLICY IF EXISTS "cache_read" ON public.page_analysis_cache;
CREATE POLICY "cache_read"
ON public.page_analysis_cache FOR SELECT
TO authenticated
USING (true);


-- IA
DROP POLICY IF EXISTS "ai_manage" ON public.ai_suggestions;
CREATE POLICY "ai_manage"
ON public.ai_suggestions FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);


-- EXECUTION LOGS
DROP POLICY IF EXISTS "logs_select" ON public.execution_logs;
CREATE POLICY "logs_select"
ON public.execution_logs FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "logs_insert" ON public.execution_logs;
CREATE POLICY "logs_insert"
ON public.execution_logs FOR INSERT
WITH CHECK (auth.uid() = user_id);


-- INTEGRATIONS
DROP POLICY IF EXISTS "integrations_manage" ON public.integrations;
CREATE POLICY "integrations_manage"
ON public.integrations FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);


-- SAVED AUTOMATIONS
DROP POLICY IF EXISTS "automations_manage" ON public.saved_automations;
CREATE POLICY "automations_manage"
ON public.saved_automations FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);


-- USAGE EVENTS
DROP POLICY IF EXISTS "usage_manage" ON public.usage_events;
CREATE POLICY "usage_manage"
ON public.usage_events FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);


-- =========================================================
-- FIM - PRODUÇÃO SAAS READY
-- =========================================================


-- =========================================================
-- FCM PUSH NOTIFICATIONS: USER DEVICES
-- =========================================================

CREATE TABLE IF NOT EXISTS public.user_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  fcm_token text NOT NULL,
  platform text CHECK (platform IN ('android', 'ios', 'web')),
  active boolean DEFAULT true,
  last_seen_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, fcm_token)
);

-- AUTO UPDATED_AT TRIGGER
DROP TRIGGER IF EXISTS update_user_devices_modtime ON public.user_devices;
CREATE TRIGGER update_user_devices_modtime
BEFORE UPDATE ON public.user_devices
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- RLS
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "devices_manage" ON public.user_devices;
CREATE POLICY "devices_manage"
ON public.user_devices FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);



-- APPENDED RECENT MIGRATIONS --

-- ============================================================
-- Migration 006: Create notifications table
-- Description: Sistema de notificações de usuário (automações,
--              atualizações, integrações, cobrança e sistema).
-- ============================================================

CREATE TABLE IF NOT EXISTS public.notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type        TEXT NOT NULL CHECK (type IN ('update', 'automation', 'integration', 'system', 'billing')),
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  image_url   TEXT,                  -- Usado em tipo 'update' (banner 16:9)
  action_type TEXT CHECK (action_type IN ('app_route', 'external_url') OR action_type IS NULL),
  action_data TEXT,                  -- Rota GoRouter ou URL externa
  metadata    JSONB DEFAULT '{}',    -- Dados extras por tipo
                                     --   automation: { automation_name, automation_status: 'success'|'error'|'warning' }
  is_read     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'notifications' AND policyname = 'Users see their own notifications'
  ) THEN
    CREATE POLICY "Users see their own notifications"
      ON public.notifications FOR SELECT
      USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'notifications' AND policyname = 'Users update their own notifications'
  ) THEN
    CREATE POLICY "Users update their own notifications"
      ON public.notifications FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- Índice para queries ordenadas por data (mais comum)
CREATE INDEX IF NOT EXISTS notifications_user_created ON public.notifications(user_id, created_at DESC);


-- Add intent field to automation_step_logs table
-- This allows the frontend to display what the backend is actually executing

ALTER TABLE automation_step_logs 
ADD COLUMN IF NOT EXISTS intent TEXT;

-- Add comment for documentation
COMMENT ON COLUMN automation_step_logs.intent IS 'Intent/objective of the automation (e.g., gemini_action, calendar_create_event, etc.)';


-- CATAS: core automation schema (definitions, runs, feedback, generation audit)
-- + automation_step_logs baseline / extensions + RLS + GIN indexes
-- Safe to re-run: uses IF NOT EXISTS / IF EXISTS guards where possible.

-- ---------------------------------------------------------------------------
-- 0) Legacy: if "automations" was used as execution log (old Python shape)
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'automations'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'automations' AND column_name = 'input_payload'
  ) THEN
    ALTER TABLE public.automations RENAME TO automation_executions_legacy;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1) Definitions: automations (trigger + steps JSONB)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.automations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name text,
  description text,
  trigger jsonb NOT NULL DEFAULT '{}'::jsonb,
  steps jsonb NOT NULL DEFAULT '[]'::jsonb,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','active','paused')),
  version integer NOT NULL DEFAULT 1,
  external_ref jsonb NOT NULL DEFAULT '{}'::jsonb,
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS update_automations_modtime ON public.automations;
CREATE TRIGGER update_automations_modtime
BEFORE UPDATE ON public.automations
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ---------------------------------------------------------------------------
-- 2) Runs: one row per execution (Temporal / n8n)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.automation_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  automation_id uuid REFERENCES public.automations(id) ON DELETE SET NULL,
  temporal_workflow_id text,
  correlation_id text NOT NULL,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','running','completed','failed','canceled')),
  run_type text NOT NULL DEFAULT 'temporal'
    CHECK (run_type IN ('temporal','n8n')),
  input_summary text,
  input_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  result_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  error_details jsonb,
  steps_summary jsonb,
  started_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT automation_runs_correlation_unique UNIQUE (correlation_id)
);

CREATE INDEX IF NOT EXISTS idx_automation_runs_user_created
  ON public.automation_runs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_automation_runs_automation
  ON public.automation_runs(automation_id)
  WHERE automation_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_automation_runs_correlation
  ON public.automation_runs(correlation_id);

DROP TRIGGER IF EXISTS update_automation_runs_modtime ON public.automation_runs;
CREATE TRIGGER update_automation_runs_modtime
BEFORE UPDATE ON public.automation_runs
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ---------------------------------------------------------------------------
-- 3) Feedback dataset (IA improvement)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.automation_feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  run_id uuid REFERENCES public.automation_runs(id) ON DELETE SET NULL,
  automation_definition_id uuid REFERENCES public.automations(id) ON DELETE SET NULL,
  rating smallint CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5)),
  labels text[] DEFAULT '{}',
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  consent boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_automation_feedback_user
  ON public.automation_feedback(user_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- 4) Generation audit (Maestro / planner)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.automation_generation_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  session_id uuid REFERENCES public.chat_sessions(id) ON DELETE SET NULL,
  intent_raw text,
  attempts jsonb NOT NULL DEFAULT '[]'::jsonb,
  errors jsonb NOT NULL DEFAULT '[]'::jsonb,
  final_plan jsonb,
  model text,
  tokens_used integer,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_automation_gen_logs_user
  ON public.automation_generation_logs(user_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- 5) automation_step_logs — create if missing (Supabase manual) or extend
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.automation_step_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  automation_id text NOT NULL,
  step_index integer NOT NULL,
  module_id text NOT NULL,
  status text NOT NULL,
  result jsonb,
  updated_at timestamptz NOT NULL DEFAULT now(),
  intent text,
  run_id uuid REFERENCES public.automation_runs(id) ON DELETE SET NULL,
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  CONSTRAINT automation_step_logs_automation_step_unique UNIQUE (automation_id, step_index)
);

ALTER TABLE public.automation_step_logs
  ADD COLUMN IF NOT EXISTS intent text;
ALTER TABLE public.automation_step_logs
  ADD COLUMN IF NOT EXISTS run_id uuid REFERENCES public.automation_runs(id) ON DELETE SET NULL;
ALTER TABLE public.automation_step_logs
  ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_automation_step_logs_run
  ON public.automation_step_logs(run_id)
  WHERE run_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_automation_step_logs_user
  ON public.automation_step_logs(user_id)
  WHERE user_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 6) Migrate saved_automations → automations (same ids)
-- ---------------------------------------------------------------------------
INSERT INTO public.automations (id, user_id, name, description, trigger, steps, status, external_ref, created_at, updated_at)
SELECT
  sa.id,
  sa.user_id,
  sa.name,
  sa.description,
  jsonb_build_object(
    'type', COALESCE(sa.trigger_type, 'manual'),
    'domain_filter', sa.domain_filter,
    'workflow_id_n8n', sa.workflow_id_n8n
  ),
  '[]'::jsonb,
  CASE WHEN sa.is_active THEN 'active' ELSE 'paused' END,
  jsonb_build_object('migrated_from', 'saved_automations'),
  sa.created_at,
  sa.updated_at
FROM public.saved_automations sa
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 7) Migrate legacy execution table → automation_runs (if renamed)
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'automation_executions_legacy'
  ) THEN
    INSERT INTO public.automation_runs (
      id, user_id, correlation_id, status, run_type, input_summary,
      input_payload, result_metadata, started_at, finished_at, created_at, updated_at
    )
    SELECT
      leg.id,
      leg.user_id,
      leg.id::text,
      CASE leg.status
        WHEN 'success' THEN 'completed'
        WHEN 'failed' THEN 'failed'
        WHEN 'running' THEN 'running'
        WHEN 'pending' THEN 'pending'
        ELSE 'completed'
      END,
      'n8n',
      COALESCE(leg.input_summary, leg.type, ''),
      COALESCE(leg.input_payload, '{}'::jsonb),
      COALESCE(leg.result_metadata, '{}'::jsonb),
      COALESCE(leg.created_at::timestamptz, now()),
      CASE WHEN leg.status IN ('success', 'failed') THEN COALESCE(leg.created_at::timestamptz, now()) ELSE NULL END,
      COALESCE(leg.created_at::timestamptz, now()),
      COALESCE(leg.created_at::timestamptz, now())
    FROM public.automation_executions_legacy leg
    ON CONFLICT (id) DO NOTHING;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 8) GIN indexes on JSONB (definitions / plans / logs)
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_automations_trigger_gin ON public.automations USING gin (trigger);
CREATE INDEX IF NOT EXISTS idx_automations_steps_gin ON public.automations USING gin (steps);
CREATE INDEX IF NOT EXISTS idx_automation_runs_input_gin ON public.automation_runs USING gin (input_payload);
CREATE INDEX IF NOT EXISTS idx_automation_gen_logs_final_plan_gin
  ON public.automation_generation_logs USING gin (final_plan);

-- ---------------------------------------------------------------------------
-- 9) RLS
-- ---------------------------------------------------------------------------
ALTER TABLE public.automations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.automation_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.automation_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.automation_generation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.automation_step_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "automations_definitions_manage" ON public.automations;
CREATE POLICY "automations_definitions_manage"
ON public.automations FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "automation_runs_select" ON public.automation_runs;
CREATE POLICY "automation_runs_select"
ON public.automation_runs FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "automation_feedback_manage" ON public.automation_feedback;
CREATE POLICY "automation_feedback_manage"
ON public.automation_feedback FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Generation logs: no client read (sensitive); backend uses service role
DROP POLICY IF EXISTS "automation_gen_logs_none" ON public.automation_generation_logs;
CREATE POLICY "automation_gen_logs_none"
ON public.automation_generation_logs FOR SELECT
USING (false);

DROP POLICY IF EXISTS "automation_step_logs_select" ON public.automation_step_logs;
CREATE POLICY "automation_step_logs_select"
ON public.automation_step_logs FOR SELECT
USING (
  user_id IS NOT NULL AND auth.uid() = user_id
);

COMMENT ON TABLE public.automations IS 'Definição versionada de automação (gatilho + steps JSONB)';
COMMENT ON TABLE public.automation_runs IS 'Histórico por execução (Temporal / n8n)';
COMMENT ON TABLE public.automation_feedback IS 'Feedback explícito do usuário para melhoria da IA';
COMMENT ON TABLE public.automation_generation_logs IS 'Auditoria de geração de planos (Maestro)';


-- Migration: 009_create_message_feedback
-- Cria a tabela para armazenar o feedback (like/dislike) das respostas da IA.
-- O objetivo é aprender quais tipos de resposta o usuário prefere.
-- + reason: motivo detalhado do feedback (opcional).

CREATE TABLE IF NOT EXISTS message_feedback (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id   UUID NOT NULL,          -- ID da mensagem na tabela `messages`
    user_id      UUID NOT NULL,          -- Quem deu o feedback
    session_id   UUID NOT NULL,          -- Sessão da mensagem (para queries analíticas)
    is_liked     BOOLEAN NOT NULL,       -- true = like, false = dislike
    reason       TEXT,                  -- Motivo do feedback (ex: clearAnswer, automationFailed, etc.)
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Garante um feedback por mensagem por usuário
    CONSTRAINT uq_feedback_message_user UNIQUE (message_id, user_id)
);

-- Índices para queries analíticas rápidas
CREATE INDEX IF NOT EXISTS idx_feedback_user_id    ON message_feedback (user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_session_id ON message_feedback (session_id);
CREATE INDEX IF NOT EXISTS idx_feedback_is_liked   ON message_feedback (is_liked);
CREATE INDEX IF NOT EXISTS idx_feedback_created_at ON message_feedback (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedback_reason     ON message_feedback (reason);

-- Trigger auto-updated_at (usa função genérica definida acima)
DROP TRIGGER IF EXISTS update_message_feedback_modtime ON message_feedback;
CREATE TRIGGER update_message_feedback_modtime
BEFORE UPDATE ON message_feedback
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- RLS: usuários só veem/manipulam seus próprios feedbacks
ALTER TABLE message_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own feedback"
    ON message_feedback FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own feedback"
    ON message_feedback FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own feedback"
    ON message_feedback FOR DELETE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can select own feedback"
    ON message_feedback FOR SELECT
    USING (auth.uid() = user_id);

-- Service-role ignora RLS automaticamente (o backend usa service_role key).


-- pgvector + ia_memory (RAG) — embedding dim 1536 (OpenAI text-embedding-3-small / ada-002 family)

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS public.ia_memory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  key text NOT NULL DEFAULT 'user_preference',
  content text NOT NULL,
  embedding vector(1536),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ia_memory_user_created
  ON public.ia_memory(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ia_memory_metadata_gin
  ON public.ia_memory USING gin (metadata);

-- Create IVFFLAT/HNSW on embedding after bulk load (see docs/arquitetura/banco-dados.md)

ALTER TABLE public.ia_memory ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ia_memory_manage" ON public.ia_memory;
CREATE POLICY "ia_memory_manage"
ON public.ia_memory FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Semantic search: only for the authenticated user (SECURITY DEFINER + auth.uid check)
CREATE OR REPLACE FUNCTION public.match_ia_memory(
  query_embedding vector(1536),
  match_user uuid,
  match_count integer DEFAULT 8
)
RETURNS TABLE (
  id uuid,
  key text,
  content text,
  similarity double precision
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Com JWT de usuário: só o próprio user_id. Com service_role, auth.uid() é null — permitido (backend).
  IF auth.uid() IS NOT NULL AND auth.uid() IS DISTINCT FROM match_user THEN
    RETURN;
  END IF;
  RETURN QUERY
  SELECT
    im.id,
    im.key,
    im.content,
    (1 - (im.embedding <=> query_embedding))::double precision AS similarity
  FROM public.ia_memory im
  WHERE im.user_id = match_user
    AND im.embedding IS NOT NULL
  ORDER BY im.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.match_ia_memory(vector(1536), uuid, integer) TO authenticated;

COMMENT ON TABLE public.ia_memory IS 'Memória semântica por usuário (RAG / pgvector)';


-- Migration 011: temporal_run_id
ALTER TABLE public.automation_runs ADD COLUMN IF NOT EXISTS temporal_run_id text;
COMMENT ON COLUMN public.automation_runs.temporal_run_id IS 'ID da run inicial do Temporal para fins de tracking e histórico';

-- Migration 012: paused status
ALTER TABLE public.automation_runs 
  DROP CONSTRAINT IF EXISTS automation_runs_status_check;
  
ALTER TABLE public.automation_runs 
  ADD CONSTRAINT automation_runs_status_check 
  CHECK (status IN ('pending', 'running', 'paused', 'completed', 'failed', 'canceled'));


-- Migration 013: user_webhook_configs
-- Tabela para configurações de webhook do usuário
-- Cada linha representa um endpoint único que pode disparar uma automação
CREATE TABLE IF NOT EXISTS public.user_webhook_configs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  automation_id uuid REFERENCES public.automations(id) ON DELETE SET NULL,
  slug text NOT NULL UNIQUE,          -- Usado na URL: /webhooks/trigger/{slug}
  name text NOT NULL,
  description text,
  hmac_secret text NOT NULL,         -- Segredo para validar HMAC-SHA256
  is_active boolean NOT NULL DEFAULT true,
  allowed_sources text[],            -- Lista de IPs/domínios permitidos (opcional)
  payload_mapping jsonb DEFAULT '{}'::jsonb, -- Mapeamento de campos do payload para o contexto
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_webhook_configs_user
  ON public.user_webhook_configs(user_id);
CREATE INDEX IF NOT EXISTS idx_user_webhook_configs_slug
  ON public.user_webhook_configs(slug);

DROP TRIGGER IF EXISTS update_user_webhook_configs_modtime ON public.user_webhook_configs;
CREATE TRIGGER update_user_webhook_configs_modtime
  BEFORE UPDATE ON public.user_webhook_configs
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- RLS
ALTER TABLE public.user_webhook_configs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "webhook_configs_manage" ON public.user_webhook_configs;
CREATE POLICY "webhook_configs_manage"
  ON public.user_webhook_configs FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

COMMENT ON TABLE public.user_webhook_configs IS 'Configurações de webhook de entrada que disparam automações Temporal';


-- =========================================================
-- CATAS - MIGRATION 014: Create handle_credit_debit RPC Function
-- =========================================================
-- Esta função debita créditos do usuário de forma atômica,
-- usando a cota mensal primeiro e depois o rollover.

CREATE OR REPLACE FUNCTION public.handle_credit_debit(
    p_user_id uuid,
    p_amount integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_profile record;
    v_monthly_remaining integer;
    v_deduct_from_monthly integer;
    v_deduct_from_rollover integer;
    v_new_monthly_used integer;
    v_new_rollover_balance integer;
    v_monthly_limit integer;
BEGIN
    -- Get user profile with lock
    SELECT 
        id,
        quota_used,
        monthly_quota_limit,
        rollover_credits,
        subscription_tier
    INTO v_profile
    FROM public.profiles
    WHERE id = p_user_id
    FOR UPDATE;
    
    -- Check if profile exists
    IF v_profile IS NULL THEN
        RETURN jsonb_build_object(
            'status', 'error',
            'message', 'User profile not found'
        );
    END IF;
    
    -- Calculate remaining monthly credits
    v_monthly_limit := COALESCE(v_profile.monthly_quota_limit, 500);
    v_monthly_remaining := GREATEST(0, v_monthly_limit - v_profile.quota_used);
    
    -- Determine how much to deduct from each pool
    IF v_monthly_remaining >= p_amount THEN
        -- Deduct all from monthly quota
        v_deduct_from_monthly := p_amount;
        v_deduct_from_rollover := 0;
    ELSE
        -- Deduct remaining monthly + rest from rollover
        v_deduct_from_monthly := v_monthly_remaining;
        v_deduct_from_rollover := p_amount - v_monthly_remaining;
    END IF;
    
    -- Check if enough total credits
    IF (v_monthly_remaining + COALESCE(v_profile.rollover_credits, 0)) < p_amount THEN
        RETURN jsonb_build_object(
            'status', 'error',
            'message', 'Insufficient credits',
            'monthly_remaining', v_monthly_remaining,
            'rollover_available', COALESCE(v_profile.rollover_credits, 0),
            'requested', p_amount
        );
    END IF;
    
    -- Calculate new balances
    v_new_monthly_used := v_profile.quota_used + v_deduct_from_monthly;
    v_new_rollover_balance := GREATEST(0, COALESCE(v_profile.rollover_credits, 0) - v_deduct_from_rollover);
    
    -- Update profile
    UPDATE public.profiles
    SET 
        quota_used = v_new_monthly_used,
        rollover_credits = v_new_rollover_balance,
        updated_at = now()
    WHERE id = p_user_id;
    
    -- Return success with details
    RETURN jsonb_build_object(
        'status', 'success',
        'amount_debited', p_amount,
        'deducted_from_monthly', v_deduct_from_monthly,
        'deducted_from_rollover', v_deduct_from_rollover,
        'new_monthly_used', v_new_monthly_used,
        'monthly_limit', v_monthly_limit,
        'new_rollover_balance', v_new_rollover_balance
    );
END;
$$;

-- Add comment for documentation
COMMENT ON FUNCTION public.handle_credit_debit(uuid, integer) IS 
'Debits credits from user account atomically. Uses monthly quota first, then rollover credits.';


-- =========================================================
-- MIGRATION: Fix RLS for chat_history and user_memory
-- =========================================================

-- Fix RLS for user_memory
ALTER TABLE public.user_memory ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_memory_manage" ON public.user_memory;
CREATE POLICY "user_memory_manage"
ON public.user_memory FOR ALL
TO authenticated
USING (auth.uid()::text = user_id)
WITH CHECK (auth.uid()::text = user_id);

-- Fix RLS for chat_history
DROP POLICY IF EXISTS "chat_history_manage" ON public.chat_history;
CREATE POLICY "chat_history_manage"
ON public.chat_history FOR ALL
TO authenticated
USING (auth.uid()::text = user_id)
WITH CHECK (auth.uid()::text = user_id);




-- =========================================================
-- TABELAS CRIADAS NO DASHBOARD (USER_MEMORY, CHAT_HISTORY)
-- =========================================================

CREATE TABLE IF NOT EXISTS public.user_memory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text UNIQUE NOT NULL,
  memory jsonb DEFAULT '{}'::jsonb,
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.chat_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  role text CHECK (role IN ('user', 'assistant')),
  content text NOT NULL,
  created_at timestamptz DEFAULT now()
);
-- 017_onboarding_smart.sql
-- Adiciona colunas de onboarding inteligente na tabela profiles e cria tabela de templates

-- 1. Alterar tabela profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS industry text,
ADD COLUMN IF NOT EXISTS role text,
ADD COLUMN IF NOT EXISTS onboarding_completed boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS onboarding_data jsonb DEFAULT '{}'::jsonb;

-- 2. Criar tabela industry_templates
CREATE TABLE IF NOT EXISTS public.industry_templates (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    industry_key text UNIQUE NOT NULL,
    industry_label text NOT NULL,
    icon_name text NOT NULL,
    pains jsonb NOT NULL DEFAULT '[]'::jsonb,
    suggested_automation_prompt text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 3. Habilitar RLS na industry_templates
ALTER TABLE public.industry_templates ENABLE ROW LEVEL SECURITY;

-- 4. Criar políticas de leitura (pública para usuários logados)
CREATE POLICY "Users can view industry templates" 
ON public.industry_templates FOR SELECT 
TO authenticated 
USING (true);

-- 5. Inserir dados iniciais (MVP)
INSERT INTO public.industry_templates (industry_key, industry_label, icon_name, pains, suggested_automation_prompt)
VALUES 
(
    'real_estate', 
    'Imobiliário', 
    'home_work', 
    '["Leads do Zap/VivaReal se perdem", "Esqueço de dar follow-up", "Muitos leads, pouco tempo"]',
    'Quero organizar meus leads do Zap Imóveis no Google Sheets e enviar um e-mail de boas-vindas automático.'
),
(
    'marketing', 
    'Marketing Digital', 
    'trending_up', 
    '["Relatórios manuais toda semana", "Dados espalhados em planilhas", "Esqueço de enviar report ao cliente"]',
    'Quero consolidar os dados das minhas campanhas em uma planilha do Google Sheets e gerar um relatório resumido com IA.'
),
(
    'legal', 
    'Advocacia', 
    'gavel', 
    '["Resumo de processos demora horas", "Prazos processuais passam batendo", "Muitos PDFs para organizar"]',
    'Quero resumir meus processos jurídicos em PDF e criar tarefas de acompanhamento no meu calendário.'
),
(
    'other', 
    'Outro', 
    'more_horiz', 
    '["Processos manuais repetitivos", "Falta de integração entre ferramentas", "Dificuldade em organizar dados"]',
    'Quero criar uma automação simples para começar a economizar tempo no meu dia a dia.'
)
ON CONFLICT (industry_key) DO UPDATE 
SET 
    industry_label = EXCLUDED.industry_label,
    icon_name = EXCLUDED.icon_name,
    pains = EXCLUDED.pains,
    suggested_automation_prompt = EXCLUDED.suggested_automation_prompt,
    updated_at = now();

-- 6. Garantir que RLS de profiles permita o update do onboarding
-- (Assumindo que já existe política de update em profiles.py, mas reforçando se necessário)
-- CREATE POLICY "Users can update their own onboarding info" ON public.profiles
-- FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
