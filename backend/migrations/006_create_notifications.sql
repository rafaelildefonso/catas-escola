-- ============================================================
-- Migration 006: Create notifications table
-- Description: Sistema de notificações de usuário (automações,
--              atualizações, integrações, cobrança e sistema).
-- ============================================================

CREATE TABLE IF NOT EXISTS public.notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type        TEXT NOT NULL CHECK (type IN ('update', 'automation', 'integration', 'system', 'billing')),
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  image_url   TEXT,                  -- Usado em tipo 'update' (banner 16:9)
  action_type TEXT CHECK (action_type IN ('app_route', 'external_url') OR action_type IS NULL),
  action_data TEXT,                  -- Rota GoRouter ou URL externa
  metadata    JSONB DEFAULT '{}',    -- Dados extras por tipo
                                     --   automation: { automation_name, automation_status: 'success'|'error'|'warning' }
  is_read     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'notifications' AND policyname = 'Users see their own notifications'
  ) THEN
    CREATE POLICY "Users see their own notifications"
      ON public.notifications FOR SELECT
      USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'notifications' AND policyname = 'Users update their own notifications'
  ) THEN
    CREATE POLICY "Users update their own notifications"
      ON public.notifications FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- Índice para queries ordenadas por data (mais comum)
CREATE INDEX IF NOT EXISTS notifications_user_created ON public.notifications(user_id, created_at DESC);
