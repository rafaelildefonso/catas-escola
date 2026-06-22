-- Renomeia colunas legadas do Temporal para nomes genéricos
-- Execute no SQL Editor do Supabase (uma única vez)

ALTER TABLE automation_runs
  RENAME COLUMN temporal_workflow_id TO execution_id;

ALTER TABLE automation_runs
  RENAME COLUMN temporal_run_id TO execution_run_id;

-- Remove a constraint antiga ANTES de atualizar os dados
-- (necessário pois o valor 'direct' pode não estar no CHECK original)
ALTER TABLE automation_runs
  DROP CONSTRAINT IF EXISTS automation_runs_run_type_check;

-- Agora atualiza registros existentes com run_type='temporal' para 'direct'
UPDATE automation_runs
  SET run_type = 'direct'
  WHERE run_type = 'temporal';

-- Ajusta o DEFAULT da coluna run_type
ALTER TABLE automation_runs ALTER COLUMN run_type SET DEFAULT 'direct';

-- Adiciona a nova constraint com os valores corretos
ALTER TABLE automation_runs
  ADD CONSTRAINT automation_runs_run_type_check
  CHECK (run_type IN ('direct', 'n8n'));
