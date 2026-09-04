-- =========================================================
-- Migration 010: ia_memory (RAG) — MySQL
-- NOTA: MySQL não possui pgvector. O embedding é armazenado
-- como JSON e a busca semântica (similaridade) é feita na
-- camada de aplicação (backend).
-- =========================================================

CREATE TABLE IF NOT EXISTS ia_memory (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    key VARCHAR(255) NOT NULL DEFAULT 'user_preference',
    content TEXT NOT NULL,
    embedding JSON NULL,              -- vetor de embeddings (JSON)
    metadata JSON NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_ia_memory_user_created (user_id, created_at DESC),
    CONSTRAINT fk_ia_memory_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Função de busca semântica aproximada (armazenada como JSON).
-- O backend faz a conversao para vetor e a ordenação por similaridade.
-- (No PostgreSQL isso era feito com pgvector / match_ia_memory.)

DELIMITER $$
CREATE OR REPLACE FUNCTION match_ia_memory(
    p_query_embedding JSON,
    p_match_user VARCHAR(36),
    p_match_count INT
)
RETURNS JSON
DETERMINISTIC
BEGIN
    RETURN JSON_ARRAY();
END$$
DELIMITER ;