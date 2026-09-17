-- =========================================================
-- Migration 013: user_webhook_configs (MySQL)
-- Tabela para configurações de webhook do usuário
-- Cada linha representa um endpoint único que pode disparar uma automação
-- =========================================================
CREATE TABLE IF NOT EXISTS user_webhook_configs (
    id             VARCHAR(36)  PRIMARY KEY DEFAULT (UUID()),
    user_id        VARCHAR(36)  NOT NULL,
    automation_id  VARCHAR(36)  NULL,
    slug           VARCHAR(255) NOT NULL,       -- Usado na URL: /webhooks/trigger/{slug}
    name           VARCHAR(255) NOT NULL,
    description    TEXT         NULL,
    hmac_secret    VARCHAR(255) NOT NULL,       -- Segredo para validar HMAC-SHA256
    is_active      TINYINT(1)   NOT NULL DEFAULT 1,
    allowed_sources JSON        NULL,           -- Lista de IPs/domínios permitidos (opcional)
    payload_mapping JSON        NOT NULL,       -- Mapeamento de campos do payload para o contexto
    created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_webhook_configs_slug (slug),
    KEY idx_user_webhook_configs_user (user_id),
    KEY idx_user_webhook_configs_slug (slug),
    CONSTRAINT fk_user_webhook_configs_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_webhook_configs_automation FOREIGN KEY (automation_id) REFERENCES automations(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER $$
CREATE TRIGGER update_user_webhook_configs_modtime
BEFORE UPDATE ON user_webhook_configs
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;