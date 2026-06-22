-- Migration 011: temporal_run_id
ALTER TABLE public.automation_runs ADD COLUMN IF NOT EXISTS temporal_run_id text;
COMMENT ON COLUMN public.automation_runs.temporal_run_id IS 'ID da run inicial do Temporal para fins de tracking e histórico';

-- Migration 012: paused status
ALTER TABLE public.automation_runs 
  DROP CONSTRAINT IF EXISTS automation_runs_status_check;
  
ALTER TABLE public.automation_runs 
  ADD CONSTRAINT automation_runs_status_check 
  CHECK (status IN ('pending', 'running', 'paused', 'completed', 'failed', 'canceled'));
