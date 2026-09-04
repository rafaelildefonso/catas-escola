-- =========================================================
-- Migration 011: temporal_run_id + Migration 012: paused status
-- (MySQL)
-- =========================================================

-- Migration 011: temporal_run_id
SET @col_temporal := (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'automation_runs' AND column_name = 'temporal_run_id');
SET @sql_temporal := IF(@col_temporal = 0,
    'ALTER TABLE automation_runs ADD COLUMN temporal_run_id VARCHAR(255) NULL', 'SELECT 1');
PREPARE stmt_temporal FROM @sql_temporal;
EXECUTE stmt_temporal;
DEALLOCATE PREPARE stmt_temporal;

-- Migration 012: paused status (ampliar CHECK de status)
ALTER TABLE automation_runs
  DROP CHECK chk_automation_runs_status;

ALTER TABLE automation_runs
  ADD CONSTRAINT chk_automation_runs_status
  CHECK (status IN ('pending', 'running', 'paused', 'completed', 'failed', 'canceled'));