-- =========================================================
-- Migration 004: Anexos (MySQL)
-- =========================================================
-- O bucket Supabase Storage ("attachments") não existe no MySQL.
-- No MySQL o controle de anexos é feito via tabela de metadados +
-- armazenamento de arquivos na aplicação (S3/disco local).
-- O backend valida o dono do arquivo (user_id) na camada de serviço.

CREATE TABLE IF NOT EXISTS attachments (
    id            VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id       VARCHAR(36) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    storage_path  VARCHAR(255) NOT NULL,
    content_type  VARCHAR(100) NULL,
    size_bytes    BIGINT NOT NULL DEFAULT 0,
    is_public     TINYINT(1) NOT NULL DEFAULT 0,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_attachments_user (user_id),
    CONSTRAINT fk_attachments_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;