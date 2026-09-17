-- =========================================================
-- Migration 008: intent field on automation_step_logs (MySQL)
-- Permite ao frontend exibir o que o backend está executando
-- =========================================================

SET @col_intent := (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'automation_step_logs' AND column_name = 'intent');
SET @sql_intent := IF(@col_intent = 0,
    'ALTER TABLE automation_step_logs ADD COLUMN intent VARCHAR(255) NULL', 'SELECT 1');
PREPARE stmt_intent FROM @sql_intent;
EXECUTE stmt_intent;
DEALLOCATE PREPARE stmt_intent;