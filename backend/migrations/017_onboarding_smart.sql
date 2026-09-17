-- =========================================================
-- 017_onboarding_smart.sql (MySQL)
-- Adiciona colunas de onboarding inteligente na tabela profiles
-- e cria tabela de templates.
-- =========================================================

-- 1. Alterar tabela profiles (adiciona se não existirem)
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

-- 2. Criar tabela industry_templates
CREATE TABLE IF NOT EXISTS industry_templates (
    id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY,
    industry_key VARCHAR(255) NOT NULL,
    industry_label VARCHAR(255) NOT NULL,
    icon_name VARCHAR(255) NOT NULL,
    pains JSON NOT NULL,
    suggested_automation_prompt TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_industry_templates_key (industry_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. NOTA RLS: política de leitura pública era exclusiva do Supabase.
-- No MySQL o acesso é controlado na aplicação.

-- 4. Inserir dados iniciais (MVP)
INSERT INTO industry_templates (industry_key, industry_label, icon_name, pains, suggested_automation_prompt)
VALUES
(
    'real_estate',
    'Imobiliário',
    'home_work',
    JSON_ARRAY('Leads do Zap/VivaReal se perdem', 'Esqueço de dar follow-up', 'Muitos leads, pouco tempo'),
    'Quero organizar meus leads do Zap Imóveis no Google Sheets e enviar um e-mail de boas-vindas automático.'
),
(
    'marketing',
    'Marketing Digital',
    'trending_up',
    JSON_ARRAY('Relatórios manuais toda semana', 'Dados espalhados em planilhas', 'Esqueço de enviar report ao cliente'),
    'Quero consolidar os dados das minhas campanhas em uma planilha do Google Sheets e gerar um relatório resumido com IA.'
),
(
    'legal',
    'Advocacia',
    'gavel',
    JSON_ARRAY('Resumo de processos demora horas', 'Prazos processuais passam batendo', 'Muitos PDFs para organizar'),
    'Quero resumir meus processos jurídicos em PDF e criar tarefas de acompanhamento no meu calendário.'
),
(
    'other',
    'Outro',
    'more_horiz',
    JSON_ARRAY('Processos manuais repetitivos', 'Falta de integração entre ferramentas', 'Dificuldade em organizar dados'),
    'Quero criar uma automação simples para começar a economizar tempo no meu dia a dia.'
)
ON DUPLICATE KEY UPDATE
    industry_label = VALUES(industry_label),
    icon_name = VALUES(icon_name),
    pains = VALUES(pains),
    suggested_automation_prompt = VALUES(suggested_automation_prompt),
    updated_at = NOW();