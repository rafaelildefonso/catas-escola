-- =========================================================
-- FCM PUSH NOTIFICATIONS: USER DEVICES (MySQL)
-- =========================================================

CREATE TABLE IF NOT EXISTS user_devices (
    id          VARCHAR(36)  PRIMARY KEY DEFAULT (UUID()),
    user_id     VARCHAR(36)  NOT NULL,
    fcm_token   TEXT         NOT NULL,
    platform    VARCHAR(255) NULL,
    active      TINYINT(1)   NOT NULL DEFAULT 1,
    last_seen_at DATETIME    NULL DEFAULT CURRENT_TIMESTAMP,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_user_devices_user_token (user_id, fcm_token(255)),
    KEY idx_user_devices_user (user_id),
    CONSTRAINT fk_user_devices_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT chk_user_devices_platform CHECK (platform IN ('android', 'ios', 'web'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- AUTO UPDATED_AT TRIGGER (substituto do trigger PG)
DELIMITER $$
CREATE TRIGGER update_user_devices_modtime
BEFORE UPDATE ON user_devices
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

-- NOTA: RLS é exclusivo do PostgreSQL. No MySQL o controle de
-- acesso é feito na camada de aplicação (backend valida user_id).