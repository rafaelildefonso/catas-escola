-- =========================================================
-- CATAS - MIGRATION 005: SYNC CREDITS SYSTEM
-- =========================================================
-- Esta migração atualiza a tabela 'profiles' para suportar o novo
-- sistema de créditos baseado em tokens (2.000 tokens = 1 crédito).

-- 1. Adicionar colunas necessárias se não existirem
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS monthly_quota_limit integer DEFAULT 500,
ADD COLUMN IF NOT EXISTS quota_used integer DEFAULT 0;

-- 2. Comentar as colunas (opcional, para documentação no Supabase)
COMMENT ON COLUMN public.profiles.monthly_quota_limit IS 'Limite mensal de créditos (tokens/2000)';
COMMENT ON COLUMN public.profiles.quota_used IS 'Quantidade de créditos consumidos no mês atual';

-- 3. Atualizar planos existentes para refletir os novos limites de créditos
-- Basic: 500 créditos
UPDATE public.profiles 
SET monthly_quota_limit = 500 
WHERE subscription_tier = 'basic' OR subscription_tier = 'free';

-- Pro: 7.500 créditos
UPDATE public.profiles 
SET monthly_quota_limit = 7500 
WHERE subscription_tier = 'pro';

-- Max: 25.000 créditos
UPDATE public.profiles 
SET monthly_quota_limit = 25000 
WHERE subscription_tier = 'max';

-- 4. Os planos agora são baseados em créditos mensais em vez de tarefas diárias.
-- O backend já foi atualizado para gerenciar a transição de tarefas para créditos.
