-- =========================================================
-- CATAS - MIGRATION 005: SYNC CREDITS SYSTEM (MySQL)
-- =========================================================
-- Esta migração atualiza a tabela 'profiles' para suportar o novo
-- sistema de créditos baseado em tokens (2.000 tokens = 1 crédito).

-- 1. Adicionar colunas necessárias (adiciona se não existirem)
SET @col_monthly := (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'profiles' AND column_name = 'monthly_quota_limit');
SET @sql_monthly := IF(@col_monthly = 0,
    'ALTER TABLE profiles ADD COLUMN monthly_quota_limit INT DEFAULT 500', 'SELECT 1');
PREPARE stmt_monthly FROM @sql_monthly;
EXECUTE stmt_monthly;
DEALLOCATE PREPARE stmt_monthly;

SET @col_quota := (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'profiles' AND column_name = 'quota_used');
SET @sql_quota := IF(@col_quota = 0,
    'ALTER TABLE profiles ADD COLUMN quota_used INT DEFAULT 0', 'SELECT 1');
PREPARE stmt_quota FROM @sql_quota;
EXECUTE stmt_quota;
DEALLOCATE PREPARE stmt_quota;

-- 2. Atualizar planos existentes para refletir os novos limites de créditos
-- Basic/Free: 500 créditos
UPDATE profiles
SET monthly_quota_limit = 500
WHERE subscription_tier IN ('basic', 'free');

-- Pro: 7.500 créditos
UPDATE profiles
SET monthly_quota_limit = 7500
WHERE subscription_tier = 'pro';

-- Max: 25.000 créditos
UPDATE profiles
SET monthly_quota_limit = 25000
WHERE subscription_tier = 'max';

-- 3. Os planos agora são baseados em créditos mensais em vez de tarefas diárias.
-- O backend já foi atualizado para gerenciar a transição de tarefas para créditos.