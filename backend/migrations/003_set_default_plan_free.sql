-- Migration: Set default subscription tier to 'free' and update existing records
-- Task: Atualização de plano: adicionar "free" no BD por default ao criar conta.

-- 1. Ensure the default value is 'free' (though it already seems to be in current schema)
ALTER TABLE public.profiles ALTER COLUMN subscription_tier SET DEFAULT 'free';

-- 2. Update existing NULL or 'BASIC' records to 'free'
UPDATE public.profiles 
SET subscription_tier = 'free' 
WHERE subscription_tier IS NULL OR subscription_tier = 'BASIC';
