-- =========================================================
-- Migration 021: termos_aceite (MySQL)
-- Registro de aceite dos Termos de Uso e do Termo de
-- Consentimento (LGPD), com versão e data, para comprovação.
-- Tabela append-only: um novo aceite gera uma nova linha.
-- =========================================================
CREATE TABLE IF NOT EXISTS termos_aceite (
    id        VARCHAR(36)  PRIMARY KEY DEFAULT (UUID()),
    user_id   VARCHAR(36)  NOT NULL,                 -- Referência: profiles.id
    tipo      VARCHAR(20)  NOT NULL,                 -- 'uso' | 'consentimento'
    versao    VARCHAR(20)  NOT NULL DEFAULT '1.0',   -- Versão do termo aceito
    origem    VARCHAR(20)  NULL,                     -- 'signup' | 'primeiro-acesso' | 'web'
    aceito_em DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_termos_aceite_user (user_id),
    KEY idx_termos_aceite_user_tipo (user_id, tipo),
    CONSTRAINT fk_termos_aceite_profile FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
