# CATAS — MySQL Database Queries

> Generated from SQLAlchemy models in `backend/models/`.  
> Compatible with **MySQL 8.0+** (Workbench).

---

## 1. Database Configuration

```sql
-- ============================================================
-- CATAS Database Setup
-- ============================================================

CREATE DATABASE IF NOT EXISTS catas_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE catas_db;

-- UUID generation support (MySQL 8.0+)
-- UUID() is built-in; no extension needed.

-- For auto-updating `updated_at` columns, triggers are used
-- instead of SQLAlchemy's `onupdate` (not supported in MySQL DDL).
```

---

## 2. Create Tables

### Table Order (respecting foreign key dependencies)

| Order | Table                        | Dependencies                         |
|-------|------------------------------|--------------------------------------|
| 1     | `users`                      | —                                    |
| 2     | `profiles`                   | —                                    |
| 3     | `browser_sessions`           | `profiles`                           |
| 4     | `chat_sessions`              | `profiles`                           |
| 5     | `messages`                   | `chat_sessions`                      |
| 6     | `integrations`               | `profiles`                           |
| 7     | `automations`                | `profiles`                           |
| 8     | `automation_runs`            | `profiles`, `automations`            |
| 9     | `automation_step_logs`       | `automation_runs`, `profiles`        |
| 10    | `automation_generation_logs` | `profiles`, `chat_sessions`          |
| 11    | `execution_logs`             | `profiles`, `ai_suggestions`, `chat_sessions` |
| 12    | `page_contexts`              | `profiles`, `browser_sessions`       |
| 13    | `ai_suggestions`             | `profiles`, `page_contexts`          |
| 14    | `page_analysis_cache`        | —                                    |
| 15    | `message_feedback`           | —                                    |
| 16    | `user_devices`               | `profiles`                           |
| 17    | `user_webhook_configs`       | `profiles`, `automations`            |
| 18    | `ia_memory`                  | `profiles`                           |

---

### 1. `users`

```sql
CREATE TABLE users (
    id            VARCHAR(36)  NOT NULL DEFAULT (UUID()),
    email         VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uk_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 2. `profiles`

```sql
CREATE TABLE profiles (
    id                    VARCHAR(36) NOT NULL DEFAULT (UUID()),
    subscription_tier     VARCHAR(255) NOT NULL DEFAULT 'basic',
    monthly_quota_limit   INT          NOT NULL DEFAULT 500,
    quota_used            INT          NOT NULL DEFAULT 0,
    rollover_credits      INT          NOT NULL DEFAULT 0,
    last_quota_reset      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    language              VARCHAR(255) NOT NULL DEFAULT 'en',
    industry              VARCHAR(255) NULL,
    role                  VARCHAR(255) NULL,
    onboarding_completed  TINYINT(1)   NOT NULL DEFAULT 0,
    onboarding_data       JSON         NULL,
    created_at            DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 3. `browser_sessions`

```sql
CREATE TABLE browser_sessions (
    id                VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id           VARCHAR(36) NULL,
    user_agent        VARCHAR(255) NULL,
    started_at        DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    CONSTRAINT fk_browser_sessions_user
        FOREIGN KEY (user_id) REFERENCES profiles(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 4. `chat_sessions`

```sql
CREATE TABLE chat_sessions (
    id            VARCHAR(36)  NOT NULL DEFAULT (UUID()),
    user_id       VARCHAR(36)  NULL,
    title         VARCHAR(255) NOT NULL DEFAULT 'Nova Conversa',
    is_onboarding TINYINT(1)   NOT NULL DEFAULT 0,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    CONSTRAINT fk_chat_sessions_user
        FOREIGN KEY (user_id) REFERENCES profiles(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 5. `messages`

```sql
CREATE TABLE messages (
    id         VARCHAR(36) NOT NULL DEFAULT (UUID()),
    session_id VARCHAR(36) NULL,
    role       VARCHAR(255) NOT NULL,
    content    TEXT         NOT NULL,
    metadata   JSON         NULL,
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    CONSTRAINT fk_messages_session
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id)
        ON DELETE CASCADE,

    CONSTRAINT messages_role_check
        CHECK (role IN ('user', 'assistant', 'system'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 6. `integrations`

```sql
CREATE TABLE integrations (
    id               VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id          VARCHAR(36) NULL,
    provider         VARCHAR(255) NOT NULL,
    is_connected     TINYINT(1)   NOT NULL DEFAULT 0,
    access_token     TEXT         NULL,
    refresh_token    TEXT         NULL,
    token_expires_at DATETIME     NULL,
    settings         JSON         NULL,
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uk_integrations_user_provider (user_id, provider),

    CONSTRAINT fk_integrations_user
        FOREIGN KEY (user_id) REFERENCES profiles(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 7. `automations`

```sql
CREATE TABLE automations (
    id            VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id       VARCHAR(36) NULL,
    name          VARCHAR(255) NULL,
    description   TEXT         NULL,
    trigger       JSON         NULL,
    steps         JSON         NULL,
    status        VARCHAR(255) NOT NULL DEFAULT 'draft',
    version       INT          NOT NULL DEFAULT 1,
    external_ref  JSON         NULL,
    expires_at    DATETIME     NULL,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    CONSTRAINT fk_automations_user
        FOREIGN KEY (user_id) REFERENCES profiles(id)
        ON DELETE CASCADE,

    CONSTRAINT automations_status_check
        CHECK (status IN ('draft', 'active', 'paused'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 8. `automation_runs`

```sql
CREATE TABLE automation_runs (
    id               VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id          VARCHAR(36) NULL,
    automation_id    VARCHAR(36) NULL,
    correlation_id   VARCHAR(255) NOT NULL,
    status           VARCHAR(255) NOT NULL DEFAULT 'pending',
    run_type         VARCHAR(255) NOT NULL DEFAULT 'direct',
    input_summary    TEXT         NULL,
    input_payload    JSON         NULL,
    result_metadata  JSON         NULL,
    error_details    JSON         NULL,
    steps_summary    JSON         NULL,
    execution_id     VARCHAR(255) NULL,
    execution_run_id VARCHAR(255) NULL,
    started_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finished_at      DATETIME     NULL,
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uk_automation_runs_correlation (correlation_id),

    CONSTRAINT fk_automation_runs_user
        FOREIGN KEY (user_id) REFERENCES profiles(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_automation_runs_automation
        FOREIGN KEY (automation_id) REFERENCES automations(id)
        ON DELETE SET NULL,

    CONSTRAINT automation_runs_status_check
        CHECK (status IN ('pending', 'running', 'paused', 'completed', 'failed', 'canceled'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 9. `automation_step_logs`

```sql
CREATE TABLE automation_step_logs (
    id            VARCHAR(36) NOT NULL DEFAULT (UUID()),
    automation_id VARCHAR(255) NOT NULL,
    step_index    INT          NOT NULL,
    module_id     VARCHAR(255) NOT NULL,
    status        VARCHAR(255) NOT NULL,
    result        JSON         NULL,
    intent        VARCHAR(255) NULL,
    run_id        VARCHAR(36)  NULL,
    user_id       VARCHAR(36)  NULL,
    updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uk_step_logs_automation_step (automation_id, step_index),

    CONSTRAINT fk_step_logs_run
        FOREIGN KEY (run_id) REFERENCES automation_runs(id)
        ON DELETE SET NULL,

    CONSTRAINT fk_step_logs_user
        FOREIGN KEY (user_id) REFERENCES profiles(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 10. `automation_generation_logs`

```sql
CREATE TABLE automation_generation_logs (
    id            VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id       VARCHAR(36) NULL,
    session_id    VARCHAR(36) NULL,
    intent_raw    TEXT         NULL,
    attempts      JSON         NULL,
    errors        JSON         NULL,
    final_plan    JSON         NULL,
    model         VARCHAR(255) NULL,
    tokens_used   INT          NULL,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    CONSTRAINT fk_generation_logs_user
        FOREIGN KEY (user_id) REFERENCES profiles(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_generation_logs_session
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 11. `ai_suggestions`

```sql
CREATE TABLE ai_suggestions (
    id                  VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id             VARCHAR(36) NULL,
    context_id          VARCHAR(36) NULL,
    title               VARCHAR(255) NOT NULL,
    description         TEXT         NULL,
    confidence_score    DOUBLE       NULL,
    payload_preview     JSON         NULL,
    suggested_workflow  VARCHAR(255) NULL,
    status              VARCHAR(255) NOT NULL DEFAULT 'pending',
    created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    CONSTRAINT fk_ai_suggestions_user
        FOREIGN KEY (user_id) REFERENCES profiles(id)
        ON DELETE CASCADE,

    CONSTRAINT ai_suggestions_status_check
        CHECK (status IN ('pending', 'accepted', 'rejected', 'executed'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 12. `execution_logs`

```sql
CREATE TABLE execution_logs (
    id              VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id         VARCHAR(36) NULL,
    suggestion_id   VARCHAR(36) NULL,
    session_id      VARCHAR(36) NULL,
    workflow_name   VARCHAR(255) NULL,
    status          VARCHAR(255) NOT NULL DEFAULT 'running',
    input_data      JSON         NULL,
    result_data     JSON         NULL,
    error_message   TEXT         NULL,
    started_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finished_at     DATETIME     NULL,

    PRIMARY KEY (id),

    CONSTRAINT fk_execution_logs_user
        FOREIGN KEY (user_id) REFERENCES profiles(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_execution_logs_suggestion
        FOREIGN KEY (suggestion_id) REFERENCES ai_suggestions(id)
        ON DELETE SET NULL,

    CONSTRAINT fk_execution_logs_session
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id)
        ON DELETE SET NULL,

    CONSTRAINT execution_logs_status_check
        CHECK (status IN ('running', 'success', 'failed'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 13. `page_contexts`

```sql
CREATE TABLE page_contexts (
    id            VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id       VARCHAR(36) NULL,
    session_id    VARCHAR(36) NULL,
    url           TEXT         NOT NULL,
    domain        VARCHAR(255) NOT NULL,
    page_title    VARCHAR(255) NULL,
    html_summary  TEXT         NULL,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    CONSTRAINT fk_page_contexts_user
        FOREIGN KEY (user_id) REFERENCES profiles(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_page_contexts_session
        FOREIGN KEY (session_id) REFERENCES browser_sessions(id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 14. `page_analysis_cache`

```sql
CREATE TABLE page_analysis_cache (
    url_hash        VARCHAR(255) NOT NULL,
    url             TEXT         NOT NULL,
    analysis_result JSON         NOT NULL,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at      DATETIME     NOT NULL,

    PRIMARY KEY (url_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 15. `message_feedback`

```sql
CREATE TABLE message_feedback (
    id         VARCHAR(36) NOT NULL DEFAULT (UUID()),
    message_id VARCHAR(255) NOT NULL,
    user_id    VARCHAR(255) NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    is_liked   TINYINT(1)   NOT NULL,
    reason     VARCHAR(255) NULL,
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uk_feedback_message_user (message_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 16. `user_devices`

```sql
CREATE TABLE user_devices (
    id            VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id       VARCHAR(36) NULL,
    fcm_token     VARCHAR(255) NOT NULL,
    platform      VARCHAR(255) NULL,
    active        TINYINT(1)   NOT NULL DEFAULT 1,
    last_seen_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uk_user_devices_user_token (user_id, fcm_token),

    CONSTRAINT fk_user_devices_user
        FOREIGN KEY (user_id) REFERENCES profiles(id)
        ON DELETE CASCADE,

    CONSTRAINT user_devices_platform_check
        CHECK (platform IN ('android', 'ios', 'web'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 17. `user_webhook_configs`

```sql
CREATE TABLE user_webhook_configs (
    id               VARCHAR(36)  NOT NULL DEFAULT (UUID()),
    user_id          VARCHAR(36)  NULL,
    automation_id    VARCHAR(36)  NULL,
    slug             VARCHAR(255) NOT NULL,
    name             VARCHAR(255) NOT NULL,
    description      TEXT         NULL,
    hmac_secret      VARCHAR(255) NOT NULL,
    is_active        TINYINT(1)   NOT NULL DEFAULT 1,
    allowed_sources  JSON         NULL,
    payload_mapping  JSON         NULL,
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    UNIQUE KEY uk_webhook_configs_slug (slug),

    CONSTRAINT fk_webhook_configs_user
        FOREIGN KEY (user_id) REFERENCES profiles(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_webhook_configs_automation
        FOREIGN KEY (automation_id) REFERENCES automations(id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 18. `ia_memory`

```sql
CREATE TABLE ia_memory (
    id         VARCHAR(36) NOT NULL DEFAULT (UUID()),
    user_id    VARCHAR(36) NULL,
    key        VARCHAR(255) NOT NULL DEFAULT 'user_preference',
    content    TEXT         NOT NULL,
    embedding  JSON         NULL,
    metadata   JSON         NULL,
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),

    CONSTRAINT fk_ia_memory_user
        FOREIGN KEY (user_id) REFERENCES profiles(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 3. `updated_at` Auto-Update Triggers

MySQL does not support `onupdate` in column definitions. Use these triggers to auto-update `updated_at` on every `UPDATE`:

```sql
-- ============================================================
-- Triggers: auto-set updated_at = NOW() on UPDATE
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$

CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$

CREATE TRIGGER trg_chat_sessions_updated_at
BEFORE UPDATE ON chat_sessions
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$

CREATE TRIGGER trg_integrations_updated_at
BEFORE UPDATE ON integrations
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$

CREATE TRIGGER trg_automations_updated_at
BEFORE UPDATE ON automations
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$

CREATE TRIGGER trg_automation_runs_updated_at
BEFORE UPDATE ON automation_runs
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$

CREATE TRIGGER trg_automation_step_logs_updated_at
BEFORE UPDATE ON automation_step_logs
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$

CREATE TRIGGER trg_message_feedback_updated_at
BEFORE UPDATE ON message_feedback
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$

CREATE TRIGGER trg_user_devices_updated_at
BEFORE UPDATE ON user_devices
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$

CREATE TRIGGER trg_user_webhook_configs_updated_at
BEFORE UPDATE ON user_webhook_configs
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$

DELIMITER ;
```

---

## 4. Useful Queries

```sql
-- ============================================================
-- Utility Queries
-- ============================================================

-- List all tables
SHOW TABLES;

-- Describe table structure
DESCRIBE users;

-- Show all foreign keys
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME,
    DELETE_RULE,
    UPDATE_RULE
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'catas_db'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;

-- Show all check constraints (MySQL 8.0.16+)
SELECT
    tc.TABLE_NAME,
    tc.CONSTRAINT_NAME,
    cc.CHECK_CLAUSE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
JOIN INFORMATION_SCHEMA.CHECK_CONSTRAINTS cc
    ON tc.CONSTRAINT_NAME = cc.CONSTRAINT_NAME
WHERE tc.TABLE_SCHEMA = 'catas_db'
  AND tc.CONSTRAINT_TYPE = 'CHECK';

-- Count rows per table
SELECT
    TABLE_NAME,
    TABLE_ROWS
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'catas_db'
ORDER BY TABLE_NAME;
```
