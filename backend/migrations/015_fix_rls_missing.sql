-- =========================================================
-- MIGRATION 015: Fix RLS (MySQL)
-- =========================================================
-- O original criava políticas RLS para user_memory e chat_history.
-- RLS é recurso exclusivo do PostgreSQL.
-- No MySQL o controle de acesso é feito na aplicação (backend).

-- Apenas garantimos que as tabelas existam e tenham índices.
CREATE TABLE IF NOT EXISTS user_memory (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    memory JSON NOT NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_memory_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS chat_history (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    role VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_chat_history_user (user_id),
    CONSTRAINT chk_chat_history_role CHECK (role IN ('user', 'assistant'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;