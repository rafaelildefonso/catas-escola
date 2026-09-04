-- =========================================================
-- Migration 001: page_analysis_cache (MySQL)
-- =========================================================

CREATE TABLE IF NOT EXISTS page_analysis_cache (
    url_hash VARCHAR(255) PRIMARY KEY,          -- Hash MD5 da URL para busca rápida
    url TEXT NOT NULL,
    analysis_result JSON NOT NULL,              -- Resultado da análise (action_cards, etc)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Índice para limpeza de cache expirado
CREATE INDEX idx_page_analysis_cache_expires_at ON page_analysis_cache(expires_at);