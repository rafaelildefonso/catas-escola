-- =========================================================
-- Migration 006: notifications (MySQL)
-- Systema de notificações de usuário (automações,
-- atualizações, integrações, cobrança e sistema).
-- =========================================================

CREATE TABLE IF NOT EXISTS notifications (
    id          VARCHAR(36)  PRIMARY KEY DEFAULT (UUID()),
    user_id     VARCHAR(36)  NOT NULL,
    type        VARCHAR(255) NOT NULL,
    title       VARCHAR(255) NOT NULL,
    body        TEXT         NOT NULL,
    image_url   VARCHAR(255) NULL,             -- Usado em tipo 'update' (banner 16:9)
    action_type VARCHAR(255) NULL,             -- 'app_route' | 'external_url' | NULL
    action_data TEXT         NULL,             -- Rota GoRouter ou URL externa
    metadata    JSON         NULL,             -- Dados extras por tipo
    is_read     TINYINT(1)   NOT NULL DEFAULT 0,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_notifications_user_created (user_id, created_at DESC),
    CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT chk_notifications_type CHECK (type IN ('update', 'automation', 'integration', 'system', 'billing')),
    CONSTRAINT chk_notifications_action_type CHECK (action_type IN ('app_route', 'external_url'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;