-- =========================================================
-- Migration 003: Default plan 'free' (MySQL)
-- =========================================================

-- 1. Define o default como 'free'
ALTER TABLE profiles ALTER COLUMN subscription_tier SET DEFAULT 'free';

-- 2. Atualiza registros NULL ou 'BASIC' para 'free'
UPDATE profiles
SET subscription_tier = 'free'
WHERE subscription_tier IS NULL OR subscription_tier = 'BASIC';