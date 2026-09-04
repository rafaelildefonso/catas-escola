-- =========================================================
-- Migration 009: message_feedback (MySQL)
-- Cria a tabela para armazenar o feedback (like/dislike) das
-- respostas da IA. O objetivo é aprender quais tipos de resposta
-- o usuário prefere.
-- =========================================================

CREATE TABLE IF NOT EXISTS message_feedback (
    id         VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    message_id VARCHAR(36) NOT NULL,          -- ID da mensagem na tabela `messages`
    user_id    VARCHAR(36) NOT NULL,          -- Quem deu o feedback
    session_id VARCHAR(36) NOT NULL,          -- Sessão da mensagem (para queries analíticas)
    is_liked   TINYINT(1) NOT NULL,           -- 1 = like, 0 = dislike
    reason     VARCHAR(255) NULL,             -- Motivo do feedback (ex: clearAnswer, automationFailed, etc.)
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Garante um feedback por mensagem por usuário
    CONSTRAINT uq_feedback_message_user UNIQUE (message_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Índices para queries analíticas rápidas
CREATE INDEX idx_feedback_user_id    ON message_feedback (user_id);
CREATE INDEX idx_feedback_session_id ON message_feedback (session_id);
CREATE INDEX idx_feedback_is_liked   ON message_feedback (is_liked);
CREATE INDEX idx_feedback_created_at ON message_feedback (created_at DESC);
CREATE INDEX idx_feedback_reason     ON message_feedback (reason);

-- Trigger auto-updated_at
DELIMITER $$
CREATE TRIGGER update_message_feedback_modtime
BEFORE UPDATE ON message_feedback
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

-- NOTA: RLS é exclusivo do PostgreSQL. No MySQL o controle
-- de acesso é feito na camada de aplicação (backend).