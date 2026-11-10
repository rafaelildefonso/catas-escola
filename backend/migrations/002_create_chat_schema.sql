-- =========================================================
-- Migration 002: Schema de Chat (MySQL)
-- Data: 2026-02-12
-- =========================================================

-- ============================================
-- Tabela: chat_sessions
-- Armazena as sessões de conversa dos usuários
-- ============================================
CREATE TABLE IF NOT EXISTS chat_sessions (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    title VARCHAR(255) NOT NULL DEFAULT 'Nova Conversa',
    is_onboarding TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_chat_sessions_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Índice para buscar sessões por usuário
CREATE INDEX idx_chat_sessions_user_id ON chat_sessions(user_id);

-- Índice para ordenar por data de atualização
CREATE INDEX idx_chat_sessions_updated_at ON chat_sessions(updated_at DESC);

-- Trigger para atualizar updated_at automaticamente
DELIMITER $$
CREATE TRIGGER trigger_update_chat_sessions_updated_at
    BEFORE UPDATE ON chat_sessions
    FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

-- ============================================
-- Tabela: messages
-- Armazena as mensagens de cada sessão
-- ============================================
CREATE TABLE IF NOT EXISTS messages (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    session_id VARCHAR(36) NOT NULL,
    role VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    metadata JSON NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_messages_session FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE,
    CONSTRAINT chk_messages_role CHECK (role IN ('user', 'assistant', 'system'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Índice para buscar mensagens por sessão (ordenado por data)
CREATE INDEX idx_messages_session_id ON messages(session_id, created_at ASC);

-- Índice para buscar mensagens por role (útil para análises)
CREATE INDEX idx_messages_role ON messages(role);

-- ============================================
-- Tabela: automation_logs (legado)
-- Armazena logs de execução de automações
-- ============================================
CREATE TABLE IF NOT EXISTS automation_logs (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    intent_detected VARCHAR(255) NOT NULL,
    status VARCHAR(255) NOT NULL,
    payload_sent JSON NOT NULL,
    response_received JSON NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_automation_logs_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT chk_automation_logs_status CHECK (status IN ('success', 'failed', 'pending'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Índice para buscar logs por usuário
CREATE INDEX idx_automation_logs_user_id ON automation_logs(user_id);

-- Índice para buscar logs por status
CREATE INDEX idx_automation_logs_status ON automation_logs(status);

-- Índice para buscar logs por intenção
CREATE INDEX idx_automation_logs_intent ON automation_logs(intent_detected);

-- Índice para ordenar por data (mais recentes primeiro)
CREATE INDEX idx_automation_logs_created_at ON automation_logs(created_at DESC);

-- ============================================
-- NOTA: RLS (Row Level Security) é recurso do
-- PostgreSQL. No MySQL, o controle de
-- acesso é feito na camada de aplicação (backend).
-- ============================================