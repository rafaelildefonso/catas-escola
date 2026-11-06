CREATE TABLE IF NOT EXISTS generated_reports (
    id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    automation_id VARCHAR(36) NULL,
    automation_run_id VARCHAR(36) NULL,
    title VARCHAR(255) NOT NULL,
    summary TEXT,
    source_name VARCHAR(255),
    metrics JSON NOT NULL,
    pdf_content LONGBLOB NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_generated_reports_user_created (user_id, created_at),
    CONSTRAINT fk_generated_reports_profile FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
    CONSTRAINT fk_generated_reports_automation FOREIGN KEY (automation_id) REFERENCES automations(id) ON DELETE SET NULL,
    CONSTRAINT fk_generated_reports_run FOREIGN KEY (automation_run_id) REFERENCES automation_runs(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
