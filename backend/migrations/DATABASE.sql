-- =========================================================
-- CATAS - SCHEMA PRODUÇÃO SAAS (MYSQL)
-- =========================================================
-- Execute no MySQL Workbench na ordem, OU rode o DATABASE.sql
-- consolidado (recomendado para ambiente novo).

-- ---------------------------------------------------------
-- USERS (auth local)
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- PERFIL
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS profiles (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    subscription_tier VARCHAR(255) NOT NULL DEFAULT 'basic',
    monthly_quota_limit INT NOT NULL DEFAULT 500,
    quota_used INT NOT NULL DEFAULT 0,
    stripe_customer_id VARCHAR(255) NULL,
    stripe_subscription_id VARCHAR(255) NULL,
    subscription_status VARCHAR(30) NOT NULL DEFAULT 'inactive',
    stripe_current_period_end DATETIME NULL,
    last_quota_reset DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    language VARCHAR(255) NOT NULL DEFAULT 'en',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE UNIQUE INDEX uq_profiles_stripe_customer_id
    ON profiles (stripe_customer_id);

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
    CONSTRAINT fk_attachments_user
        FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- CHAT
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS chat_sessions (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NULL,
    title VARCHAR(255) NOT NULL DEFAULT 'Nova Conversa',
    is_onboarding TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_chat_sessions_user (user_id),
    CONSTRAINT fk_chat_sessions_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS messages (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    session_id VARCHAR(36) NULL,
    role VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    metadata JSON NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_messages_session (session_id),
    CONSTRAINT fk_messages_session FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE,
    CONSTRAINT messages_role_check CHECK (role IN ('user','assistant','system'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- AUTOMATION LOGS (legado)
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS automation_logs (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NULL,
    intent_detected VARCHAR(255) NOT NULL,
    status VARCHAR(255) NOT NULL,
    payload_sent JSON NOT NULL,
    response_received JSON NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_automation_logs_user (user_id),
    CONSTRAINT fk_automation_logs_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- CONTEXTO
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS browser_sessions (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NULL,
    user_agent VARCHAR(255) NULL,
    started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_browser_sessions_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS page_contexts (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NULL,
    session_id VARCHAR(36) NULL,
    url TEXT NOT NULL,
    domain VARCHAR(255) NOT NULL,
    page_title VARCHAR(255) NULL,
    html_summary TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_page_contexts_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT fk_page_contexts_session FOREIGN KEY (session_id) REFERENCES browser_sessions(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS page_analysis_cache (
    url_hash VARCHAR(255) NOT NULL,
    url TEXT NOT NULL,
    analysis_result JSON NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME NOT NULL,
    PRIMARY KEY (url_hash),
    KEY idx_page_analysis_cache_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- IA
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS ai_suggestions (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NULL,
    context_id VARCHAR(36) NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NULL,
    confidence_score DOUBLE NULL,
    payload_preview JSON NULL,
    suggested_workflow VARCHAR(255) NULL,
    status VARCHAR(255) NOT NULL DEFAULT 'pending',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_ai_suggestions_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT ai_suggestions_status_check CHECK (status IN ('pending','accepted','rejected','executed'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS execution_logs (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NULL,
    suggestion_id VARCHAR(36) NULL,
    session_id VARCHAR(36) NULL,
    workflow_name VARCHAR(255) NULL,
    status VARCHAR(255) NOT NULL DEFAULT 'running',
    input_data JSON NULL,
    result_data JSON NULL,
    error_message TEXT NULL,
    started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finished_at DATETIME NULL,
    PRIMARY KEY (id),
    KEY idx_execution_logs_user (user_id),
    CONSTRAINT fk_execution_logs_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT fk_execution_logs_suggestion FOREIGN KEY (suggestion_id) REFERENCES ai_suggestions(id) ON DELETE SET NULL,
    CONSTRAINT fk_execution_logs_session FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE SET NULL,
    CONSTRAINT execution_logs_status_check CHECK (status IN ('running','success','failed'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- AUTOMAÇÕES / INTEGRAÇÕES
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS integrations (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NULL,
    provider VARCHAR(255) NOT NULL,
    is_connected TINYINT(1) NOT NULL DEFAULT 0,
    access_token TEXT NULL,
    refresh_token TEXT NULL,
    token_expires_at DATETIME NULL,
    settings JSON NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_integrations_user_provider (user_id, provider),
    CONSTRAINT fk_integrations_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS saved_automations (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NULL,
    name VARCHAR(255) NULL,
    description TEXT NULL,
    workflow_id_n8n VARCHAR(255) NULL,
    trigger_type VARCHAR(255) NOT NULL DEFAULT 'manual',
    domain_filter VARCHAR(255) NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_saved_automations_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS usage_events (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NULL,
    event_type VARCHAR(255) NULL,
    metadata JSON NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_usage_events_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- AUTO UPDATED_AT (triggers MySQL)
-- ---------------------------------------------------------
DROP TRIGGER IF EXISTS trg_profiles_updated_at;
DELIMITER $$
CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_chat_sessions_updated_at;
DELIMITER $$
CREATE TRIGGER trg_chat_sessions_updated_at
BEFORE UPDATE ON chat_sessions
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_integrations_updated_at;
DELIMITER $$
CREATE TRIGGER trg_integrations_updated_at
BEFORE UPDATE ON integrations
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_saved_automations_updated_at;
DELIMITER $$
CREATE TRIGGER trg_saved_automations_updated_at
BEFORE UPDATE ON saved_automations
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

-- ---------------------------------------------------------
-- FCM PUSH NOTIFICATIONS: USER DEVICES
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_devices (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    fcm_token VARCHAR(255) NOT NULL,
    platform VARCHAR(255) NULL,
    active TINYINT(1) NOT NULL DEFAULT 1,
    last_seen_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_devices_user_token (user_id, fcm_token),
    CONSTRAINT fk_user_devices_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT user_devices_platform_check CHECK (platform IN ('android','ios','web'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_user_devices_updated_at;
DELIMITER $$
CREATE TRIGGER trg_user_devices_updated_at
BEFORE UPDATE ON user_devices
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

-- ---------------------------------------------------------
-- Migration 006: notifications
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    type VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    image_url VARCHAR(255) NULL,
    action_type VARCHAR(255) NULL,
    action_data TEXT NULL,
    metadata JSON NULL,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_notifications_user_created (user_id, created_at DESC),
    CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT notifications_type_check CHECK (type IN ('update','automation','integration','system','billing')),
    CONSTRAINT notifications_action_type_check CHECK (action_type IN ('app_route','external_url'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- AUTOMAÇÕES CORE (definitions, runs, feedback, generation, step logs)
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS automations (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NULL,
    name VARCHAR(255) NULL,
    description TEXT NULL,
    trigger JSON NOT NULL,
    steps JSON NOT NULL,
    status VARCHAR(255) NOT NULL DEFAULT 'draft',
    version INT NOT NULL DEFAULT 1,
    external_ref JSON NOT NULL,
    expires_at DATETIME NULL,
    next_run_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_automations_user (user_id),
    KEY idx_automations_due (status, next_run_at),
    CONSTRAINT fk_automations_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT automations_status_check CHECK (status IN ('draft','active','paused'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_automations_updated_at;
DELIMITER $$
CREATE TRIGGER trg_automations_updated_at
BEFORE UPDATE ON automations
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

CREATE TABLE IF NOT EXISTS automation_runs (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NULL,
    automation_id VARCHAR(36) NULL,
    correlation_id VARCHAR(255) NOT NULL,
    status VARCHAR(255) NOT NULL DEFAULT 'pending',
    run_type VARCHAR(255) NOT NULL DEFAULT 'temporal',
    input_summary TEXT NULL,
    input_payload JSON NOT NULL,
    result_metadata JSON NOT NULL,
    error_details JSON NULL,
    steps_summary JSON NULL,
    started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finished_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY automation_runs_correlation_unique (correlation_id),
    KEY idx_automation_runs_user_created (user_id, created_at DESC),
    KEY idx_automation_runs_automation (automation_id),
    KEY idx_automation_runs_correlation (correlation_id),
    CONSTRAINT fk_automation_runs_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT fk_automation_runs_automation FOREIGN KEY (automation_id) REFERENCES automations(id) ON DELETE SET NULL,
    CONSTRAINT automation_runs_status_check CHECK (status IN ('pending','running','paused','completed','failed','canceled')),
    CONSTRAINT automation_runs_run_type_check CHECK (run_type IN ('direct','n8n'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_automation_runs_updated_at;
DELIMITER $$
CREATE TRIGGER trg_automation_runs_updated_at
BEFORE UPDATE ON automation_runs
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

CREATE TABLE IF NOT EXISTS automation_feedback (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    run_id VARCHAR(36) NULL,
    automation_definition_id VARCHAR(36) NULL,
    rating SMALLINT NULL,
    labels JSON NOT NULL,
    payload JSON NOT NULL,
    consent TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_automation_feedback_user (user_id, created_at DESC),
    CONSTRAINT fk_automation_feedback_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT fk_automation_feedback_run FOREIGN KEY (run_id) REFERENCES automation_runs(id) ON DELETE SET NULL,
    CONSTRAINT fk_automation_feedback_def FOREIGN KEY (automation_definition_id) REFERENCES automations(id) ON DELETE SET NULL,
    CONSTRAINT automation_feedback_rating_check CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS automation_generation_logs (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    session_id VARCHAR(36) NULL,
    intent_raw TEXT NULL,
    attempts JSON NOT NULL,
    errors JSON NOT NULL,
    final_plan JSON NULL,
    model VARCHAR(255) NULL,
    tokens_used INT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_automation_gen_logs_user (user_id, created_at DESC),
    CONSTRAINT fk_automation_gen_logs_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT fk_automation_gen_logs_session FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS automation_step_logs (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    automation_id VARCHAR(255) NOT NULL,
    step_index INT NOT NULL,
    module_id VARCHAR(255) NOT NULL,
    status VARCHAR(255) NOT NULL,
    result JSON NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    intent VARCHAR(255) NULL,
    run_id VARCHAR(36) NULL,
    user_id VARCHAR(36) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY automation_step_logs_run_step_unique (run_id, step_index),
    KEY idx_automation_step_logs_run (run_id),
    KEY idx_automation_step_logs_user (user_id),
    CONSTRAINT fk_automation_step_logs_run FOREIGN KEY (run_id) REFERENCES automation_runs(id) ON DELETE SET NULL,
    CONSTRAINT fk_automation_step_logs_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_automation_step_logs_updated_at;
DELIMITER $$
CREATE TRIGGER trg_automation_step_logs_updated_at
BEFORE UPDATE ON automation_step_logs
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

-- Migrate saved_automations -> automations (mesmos ids)
INSERT INTO automations (id, user_id, name, description, trigger, steps, status, external_ref, created_at, updated_at)
SELECT
    sa.id,
    sa.user_id,
    sa.name,
    sa.description,
    JSON_OBJECT(
        'type', COALESCE(sa.trigger_type, 'manual'),
        'domain_filter', sa.domain_filter,
        'workflow_id_n8n', sa.workflow_id_n8n
    ),
    JSON_ARRAY(),
    IF(sa.is_active = 1, 'active', 'paused'),
    JSON_OBJECT('migrated_from', 'saved_automations'),
    sa.created_at,
    sa.updated_at
FROM saved_automations sa
ON DUPLICATE KEY UPDATE id = id;

-- ---------------------------------------------------------
-- message_feedback (+ reason)
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS message_feedback (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    message_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    session_id VARCHAR(36) NOT NULL,
    is_liked TINYINT(1) NOT NULL,
    reason VARCHAR(255) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_feedback_message_user (message_id, user_id),
    KEY idx_feedback_user_id (user_id),
    KEY idx_feedback_session_id (session_id),
    KEY idx_feedback_is_liked (is_liked),
    KEY idx_feedback_created_at (created_at DESC),
    KEY idx_feedback_reason (reason)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_message_feedback_updated_at;
DELIMITER $$
CREATE TRIGGER trg_message_feedback_updated_at
BEFORE UPDATE ON message_feedback
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

-- ---------------------------------------------------------
-- ia_memory (RAG) — embedding armazenado como JSON
-- (MySQL nao possui pgvector; busca semantica feita na aplicacao)
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS ia_memory (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    key VARCHAR(255) NOT NULL DEFAULT 'user_preference',
    content TEXT NOT NULL,
    embedding JSON NULL,
    metadata JSON NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_ia_memory_user_created (user_id, created_at DESC),
    CONSTRAINT fk_ia_memory_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- user_webhook_configs
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_webhook_configs (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    automation_id VARCHAR(36) NULL,
    slug VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NULL,
    hmac_secret VARCHAR(255) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    allowed_sources JSON NULL,
    payload_mapping JSON NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_webhook_configs_slug (slug),
    KEY idx_user_webhook_configs_user (user_id),
    CONSTRAINT fk_user_webhook_configs_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_webhook_configs_automation FOREIGN KEY (automation_id) REFERENCES automations(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TRIGGER IF EXISTS trg_user_webhook_configs_updated_at;
DELIMITER $$
CREATE TRIGGER trg_user_webhook_configs_updated_at
BEFORE UPDATE ON user_webhook_configs
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

-- ---------------------------------------------------------
-- Onboarding: colunas em profiles + industry_templates
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS industry_templates (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    industry_key VARCHAR(255) NOT NULL,
    industry_label VARCHAR(255) NOT NULL,
    icon_name VARCHAR(255) NOT NULL,
    pains JSON NOT NULL,
    suggested_automation_prompt TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_industry_templates_key (industry_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO industry_templates (industry_key, industry_label, icon_name, pains, suggested_automation_prompt)
VALUES
    ('real_estate', 'Imobiliário', 'home_work',
        JSON_ARRAY('Leads do Zap/VivaReal se perdem', 'Esqueço de dar follow-up', 'Muitos leads, pouco tempo'),
        'Quero organizar meus leads do Zap Imóveis no Google Sheets e enviar um e-mail de boas-vindas automático.'),
    ('marketing', 'Marketing Digital', 'trending_up',
        JSON_ARRAY('Relatórios manuais toda semana', 'Dados espalhados em planilhas', 'Esqueço de enviar report ao cliente'),
        'Quero consolidar os dados das minhas campanhas em uma planilha do Google Sheets e gerar um relatório resumido com IA.'),
    ('legal', 'Advocacia', 'gavel',
        JSON_ARRAY('Resumo de processos demora horas', 'Prazos processuais passam batendo', 'Muitos PDFs para organizar'),
        'Quero resumir meus processos jurídicos em PDF e criar tarefas de acompanhamento no meu calendário.'),
    ('other', 'Outro', 'more_horiz',
        JSON_ARRAY('Processos manuais repetitivos', 'Falta de integração entre ferramentas', 'Dificuldade em organizar dados'),
        'Quero criar uma automação simples para começar a economizar tempo no meu dia a dia.')
ON DUPLICATE KEY UPDATE
    industry_label = VALUES(industry_label),
    icon_name = VALUES(icon_name),
    pains = VALUES(pains),
    suggested_automation_prompt = VALUES(suggested_automation_prompt),
    updated_at = NOW();

-- As colunas abaixo sao adicionadas se ainda nao existirem.
-- (MySQL 8.0 nao suporta 'ADD COLUMN IF NOT EXISTS'; use uma vez em ambiente novo.)
SET @col_industry := (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'profiles' AND column_name = 'industry');
SET @sql_industry := IF(@col_industry = 0,
    'ALTER TABLE profiles ADD COLUMN industry VARCHAR(255) NULL', 'SELECT 1');
PREPARE stmt_industry FROM @sql_industry;
EXECUTE stmt_industry;
DEALLOCATE PREPARE stmt_industry;

SET @col_role := (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'profiles' AND column_name = 'role');
SET @sql_role := IF(@col_role = 0,
    'ALTER TABLE profiles ADD COLUMN role VARCHAR(255) NULL', 'SELECT 1');
PREPARE stmt_role FROM @sql_role;
EXECUTE stmt_role;
DEALLOCATE PREPARE stmt_role;

SET @col_onboarding_completed := (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'profiles' AND column_name = 'onboarding_completed');
SET @sql_onboarding_completed := IF(@col_onboarding_completed = 0,
    'ALTER TABLE profiles ADD COLUMN onboarding_completed TINYINT(1) NOT NULL DEFAULT 0', 'SELECT 1');
PREPARE stmt_onboarding_completed FROM @sql_onboarding_completed;
EXECUTE stmt_onboarding_completed;
DEALLOCATE PREPARE stmt_onboarding_completed;

SET @col_onboarding_data := (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'profiles' AND column_name = 'onboarding_data');
SET @sql_onboarding_data := IF(@col_onboarding_data = 0,
    'ALTER TABLE profiles ADD COLUMN onboarding_data JSON NULL', 'SELECT 1');
PREPARE stmt_onboarding_data FROM @sql_onboarding_data;
EXECUTE stmt_onboarding_data;
DEALLOCATE PREPARE stmt_onboarding_data;

SET @col_rollover_credits := (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'profiles' AND column_name = 'rollover_credits');
SET @sql_rollover_credits := IF(@col_rollover_credits = 0,
    'ALTER TABLE profiles ADD COLUMN rollover_credits INT NOT NULL DEFAULT 0', 'SELECT 1');
PREPARE stmt_rollover_credits FROM @sql_rollover_credits;
EXECUTE stmt_rollover_credits;
DEALLOCATE PREPARE stmt_rollover_credits;

-- ---------------------------------------------------------
-- dashboard/user_memory / chat_history (legado)
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_memory (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    memory JSON NOT NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_memory_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS chat_history (
    id VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    role VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_chat_history_user (user_id),
    CONSTRAINT chat_history_role_check CHECK (role IN ('user','assistant'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- FIM - SCHEMA MYSQL
-- =========================================================
