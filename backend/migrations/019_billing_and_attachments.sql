-- Execute no banco MySQL de produção antes de atualizar a aplicação.
ALTER TABLE profiles
    ADD COLUMN stripe_customer_id VARCHAR(255) NULL,
    ADD COLUMN stripe_subscription_id VARCHAR(255) NULL,
    ADD COLUMN subscription_status VARCHAR(30) NOT NULL DEFAULT 'inactive',
    ADD COLUMN stripe_current_period_end DATETIME NULL,
    ADD UNIQUE KEY uq_profiles_stripe_customer_id (stripe_customer_id);

CREATE TABLE IF NOT EXISTS attachments (
    id            VARCHAR(36) NOT NULL,
    user_id       VARCHAR(36) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    storage_path  VARCHAR(512) NOT NULL,
    content_type  VARCHAR(100) NOT NULL,
    size_bytes    BIGINT NOT NULL,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_attachments_user_created (user_id, created_at),
    CONSTRAINT fk_attachments_profile
        FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
