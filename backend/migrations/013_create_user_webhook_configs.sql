-- Migration 013: user_webhook_configs
-- Tabela para configurações de webhook do usuário
-- Cada linha representa um endpoint único que pode disparar uma automação
CREATE TABLE IF NOT EXISTS public.user_webhook_configs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  automation_id uuid REFERENCES public.automations(id) ON DELETE SET NULL,
  slug text NOT NULL UNIQUE,          -- Usado na URL: /webhooks/trigger/{slug}
  name text NOT NULL,
  description text,
  hmac_secret text NOT NULL,         -- Segredo para validar HMAC-SHA256
  is_active boolean NOT NULL DEFAULT true,
  allowed_sources text[],            -- Lista de IPs/domínios permitidos (opcional)
  payload_mapping jsonb DEFAULT '{}'::jsonb, -- Mapeamento de campos do payload para o contexto
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_webhook_configs_user
  ON public.user_webhook_configs(user_id);
CREATE INDEX IF NOT EXISTS idx_user_webhook_configs_slug
  ON public.user_webhook_configs(slug);

DROP TRIGGER IF EXISTS update_user_webhook_configs_modtime ON public.user_webhook_configs;
CREATE TRIGGER update_user_webhook_configs_modtime
  BEFORE UPDATE ON public.user_webhook_configs
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- RLS
ALTER TABLE public.user_webhook_configs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "webhook_configs_manage" ON public.user_webhook_configs;
CREATE POLICY "webhook_configs_manage"
  ON public.user_webhook_configs FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

COMMENT ON TABLE public.user_webhook_configs IS 'Configurações de webhook de entrada que disparam automações Temporal';
