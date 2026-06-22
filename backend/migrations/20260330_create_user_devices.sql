-- =========================================================
-- FCM PUSH NOTIFICATIONS: USER DEVICES
-- =========================================================

CREATE TABLE IF NOT EXISTS public.user_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  fcm_token text NOT NULL,
  platform text CHECK (platform IN ('android', 'ios', 'web')),
  active boolean DEFAULT true,
  last_seen_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, fcm_token)
);

-- AUTO UPDATED_AT TRIGGER
DROP TRIGGER IF EXISTS update_user_devices_modtime ON public.user_devices;
CREATE TRIGGER update_user_devices_modtime
BEFORE UPDATE ON public.user_devices
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- RLS
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "devices_manage" ON public.user_devices;
CREATE POLICY "devices_manage"
ON public.user_devices FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
