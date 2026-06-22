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
