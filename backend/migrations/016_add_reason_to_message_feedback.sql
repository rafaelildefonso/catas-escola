-- =========================================================
-- Migration 016: Add reason column to message_feedback (MySQL)
-- Adiciona o campo 'reason' para capturar o motivo
-- do feedback (like/dislike) com opções específicas.
-- =========================================================

-- Adicionar coluna reason (texto curto para motivo do feedback)
SET @col_reason := (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'message_feedback' AND column_name = 'reason');
SET @sql_reason := IF(@col_reason = 0,
    'ALTER TABLE message_feedback ADD COLUMN reason VARCHAR(255) NULL', 'SELECT 1');
PREPARE stmt_reason FROM @sql_reason;
EXECUTE stmt_reason;
DEALLOCATE PREPARE stmt_reason;

-- Índice para queries por reason (analytics)
CREATE INDEX idx_feedback_reason ON message_feedback (reason);

-- Atualizar trigger para atualizar updated_at automaticamente (se não existir)
SET @trg_exists := (SELECT COUNT(*) FROM information_schema.triggers
    WHERE trigger_schema = DATABASE() AND trigger_name = 'update_message_feedback_updated_at');
SET @sql_trg := IF(@trg_exists = 0,
    'CREATE TRIGGER update_message_feedback_updated_at BEFORE UPDATE ON message_feedback FOR EACH ROW SET NEW.updated_at = NOW()',
    'SELECT 1');
PREPARE stmt_trg FROM @sql_trg;
EXECUTE stmt_trg;
DEALLOCATE PREPARE stmt_trg;