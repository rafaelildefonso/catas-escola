-- =========================================================
-- 017_rename_temporal_columns.sql (MySQL)
-- Renomeia colunas legadas do Temporal para nomes genéricos
-- Execute no MySQL Workbench (uma única vez)
-- =========================================================

ALTER TABLE automation_runs
  RENAME COLUMN temporal_workflow_id TO execution_id;

SET @col_temporal_run := (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'automation_runs' AND column_name = 'temporal_run_id');
SET @sql_temporal_run := IF(@col_temporal_run = 1,
    'ALTER TABLE automation_runs RENAME COLUMN temporal_run_id TO execution_run_id', 'SELECT 1');
PREPARE stmt_temporal_run FROM @sql_temporal_run;
EXECUTE stmt_temporal_run;
DEALLOCATE PREPARE stmt_temporal_run;

-- Remove a constraint antiga ANTES de atualizar os dados
ALTER TABLE automation_runs
  DROP CHECK chk_automation_runs_run_type;

-- Atualiza registros existentes com run_type='temporal' para 'direct'
UPDATE automation_runs
SET run_type = 'direct'
WHERE run_type = 'temporal';

-- Ajusta o DEFAULT da coluna run_type
ALTER TABLE automation_runs ALTER COLUMN run_type SET DEFAULT 'direct';

-- Adiciona a nova constraint com os valores corretos
ALTER TABLE automation_runs
  ADD CONSTRAINT chk_automation_runs_run_type
  CHECK (run_type IN ('direct', 'n8n'));