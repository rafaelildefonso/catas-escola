-- 017_onboarding_smart.sql
-- Adiciona colunas de onboarding inteligente na tabela profiles e cria tabela de templates

-- 1. Alterar tabela profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS industry text,
ADD COLUMN IF NOT EXISTS role text,
ADD COLUMN IF NOT EXISTS onboarding_completed boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS onboarding_data jsonb DEFAULT '{}'::jsonb;

-- 2. Criar tabela industry_templates
CREATE TABLE IF NOT EXISTS public.industry_templates (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    industry_key text UNIQUE NOT NULL,
    industry_label text NOT NULL,
    icon_name text NOT NULL,
    pains jsonb NOT NULL DEFAULT '[]'::jsonb,
    suggested_automation_prompt text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 3. Habilitar RLS na industry_templates
ALTER TABLE public.industry_templates ENABLE ROW LEVEL SECURITY;

-- 4. Criar políticas de leitura (pública para usuários logados)
CREATE POLICY "Users can view industry templates" 
ON public.industry_templates FOR SELECT 
TO authenticated 
USING (true);

-- 5. Inserir dados iniciais (MVP)
INSERT INTO public.industry_templates (industry_key, industry_label, icon_name, pains, suggested_automation_prompt)
VALUES 
(
    'real_estate', 
    'Imobiliário', 
    'home_work', 
    '["Leads do Zap/VivaReal se perdem", "Esqueço de dar follow-up", "Muitos leads, pouco tempo"]',
    'Quero organizar meus leads do Zap Imóveis no Google Sheets e enviar um e-mail de boas-vindas automático.'
),
(
    'marketing', 
    'Marketing Digital', 
    'trending_up', 
    '["Relatórios manuais toda semana", "Dados espalhados em planilhas", "Esqueço de enviar report ao cliente"]',
    'Quero consolidar os dados das minhas campanhas em uma planilha do Google Sheets e gerar um relatório resumido com IA.'
),
(
    'legal', 
    'Advocacia', 
    'gavel', 
    '["Resumo de processos demora horas", "Prazos processuais passam batendo", "Muitos PDFs para organizar"]',
    'Quero resumir meus processos jurídicos em PDF e criar tarefas de acompanhamento no meu calendário.'
),
(
    'other', 
    'Outro', 
    'more_horiz', 
    '["Processos manuais repetitivos", "Falta de integração entre ferramentas", "Dificuldade em organizar dados"]',
    'Quero criar uma automação simples para começar a economizar tempo no meu dia a dia.'
)
ON CONFLICT (industry_key) DO UPDATE 
SET 
    industry_label = EXCLUDED.industry_label,
    icon_name = EXCLUDED.icon_name,
    pains = EXCLUDED.pains,
    suggested_automation_prompt = EXCLUDED.suggested_automation_prompt,
    updated_at = now();

-- 6. Garantir que RLS de profiles permita o update do onboarding
-- (Assumindo que já existe política de update em profiles.py, mas reforçando se necessário)
-- CREATE POLICY "Users can update their own onboarding info" ON public.profiles
-- FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
