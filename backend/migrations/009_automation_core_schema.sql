-- =========================================================
-- CATAS: core automation schema (MySQL)
-- definitions (automations), runs, feedback, generation audit
-- + automation_step_logs baseline / extensões
-- =========================================================

-- ---------------------------------------------------------------------------
-- 1) Definitions: automations (trigger + steps JSON)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS automations (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    name VARCHAR(255) NULL,
    description TEXT NULL,
    trigger JSON NOT NULL,
    steps JSON NOT NULL,
    status VARCHAR(255) NOT NULL DEFAULT 'draft',
    version INT NOT NULL DEFAULT 1,
    external_ref JSON NOT NULL,
    expires_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_automations_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT chk_automations_status CHECK (status IN ('draft','active','paused'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER $$
CREATE TRIGGER update_automations_modtime
BEFORE UPDATE ON automations
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

-- ---------------------------------------------------------------------------
-- 2) Runs: one row per execution (Temporal / n8n)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS automation_runs (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    automation_id VARCHAR(36) NULL,
    temporal_workflow_id VARCHAR(255) NULL,
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
    UNIQUE KEY automation_runs_correlation_unique (correlation_id),
    KEY idx_automation_runs_user_created (user_id, created_at DESC),
    KEY idx_automation_runs_automation (automation_id),
    KEY idx_automation_runs_correlation (correlation_id),
    CONSTRAINT fk_automation_runs_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT fk_automation_runs_automation FOREIGN KEY (automation_id) REFERENCES automations(id) ON DELETE SET NULL,
    CONSTRAINT chk_automation_runs_status CHECK (status IN ('pending','running','completed','failed','canceled')),
    CONSTRAINT chk_automation_runs_run_type CHECK (run_type IN ('temporal','n8n'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER $$
CREATE TRIGGER update_automation_runs_modtime
BEFORE UPDATE ON automation_runs
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$
DELIMITER ;

-- ---------------------------------------------------------------------------
-- 3) Feedback dataset (IA improvement)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS automation_feedback (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    run_id VARCHAR(36) NULL,
    automation_definition_id VARCHAR(36) NULL,
    rating SMALLINT NULL,
    labels JSON NOT NULL,
    payload JSON NOT NULL,
    consent TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_automation_feedback_user (user_id, created_at DESC),
    CONSTRAINT fk_automation_feedback_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT fk_automation_feedback_run FOREIGN KEY (run_id) REFERENCES automation_runs(id) ON DELETE SET NULL,
    CONSTRAINT fk_automation_feedback_def FOREIGN KEY (automation_definition_id) REFERENCES automations(id) ON DELETE SET NULL,
    CONSTRAINT chk_automation_feedback_rating CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 4) Generation audit (Maestro / planner)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS automation_generation_logs (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    session_id VARCHAR(36) NULL,
    intent_raw TEXT NULL,
    attempts JSON NOT NULL,
    errors JSON NOT NULL,
    final_plan JSON NULL,
    model VARCHAR(255) NULL,
    tokens_used INT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_automation_gen_logs_user (user_id, created_at DESC),
    CONSTRAINT fk_automation_gen_logs_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT fk_automation_gen_logs_session FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 5) automation_step_logs
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS automation_step_logs (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    automation_id VARCHAR(255) NOT NULL,
    step_index INT NOT NULL,
    module_id VARCHAR(255) NOT NULL,
    status VARCHAR(255) NOT NULL,
    result JSON NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    intent VARCHAR(255) NULL,
    run_id VARCHAR(36) NULL,
    user_id VARCHAR(36) NULL,
    UNIQUE KEY automation_step_logs_automation_step_unique (automation_id, step_index),
    KEY idx_automation_step_logs_run (run_id),
    KEY idx_automation_step_logs_user (user_id),
    CONSTRAINT fk_automation_step_logs_run FOREIGN KEY (run_id) REFERENCES automation_runs(id) ON DELETE SET NULL,
    CONSTRAINT fk_automation_step_logs_user FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 6) Migrate saved_automations -> automations (mesmos ids)
-- ---------------------------------------------------------------------------
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
ON DUPLICATE KEY UPDATE id = VALUES(id);

-- ---------------------------------------------------------------------------
-- 7) Migrate legacy execution table -> automation_runs (se renomeada)
-- ---------------------------------------------------------------------------
INSERT INTO automation_runs (
    id, user_id, correlation_id, status, run_type, input_summary,
    input_payload, result_metadata, started_at, finished_at, created_at, updated_at
)
SELECT
    leg.id,
    leg.user_id,
    leg.id,
    CASE leg.status
        WHEN 'success' THEN 'completed'
        WHEN 'failed' THEN 'failed'
        WHEN 'running' THEN 'running'
        WHEN 'pending' THEN 'pending'
        ELSE 'completed'
    END,
    'n8n',
    COALESCE(leg.input_summary, leg.type, ''),
    COALESCE(leg.input_payload, JSON_OBJECT()),
    COALESCE(leg.result_metadata, JSON_OBJECT()),
    COALESCE(leg.created_at, NOW()),
    IF(leg.status IN ('success', 'failed'), COALESCE(leg.created_at, NOW()), NULL),
    COALESCE(leg.created_at, NOW()),
    COALESCE(leg.created_at, NOW())
FROM automation_executions_legacy leg
WHERE EXISTS (SELECT 1 FROM information_schema.tables
              WHERE table_schema = DATABASE() AND table_name = 'automation_executions_legacy')
ON DUPLICATE KEY UPDATE id = VALUES(id);