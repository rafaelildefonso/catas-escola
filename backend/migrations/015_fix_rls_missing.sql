-- =========================================================
-- MIGRATION: Fix RLS for chat_history and user_memory
-- =========================================================

-- Fix RLS for user_memory
ALTER TABLE public.user_memory ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_memory_manage" ON public.user_memory;
CREATE POLICY "user_memory_manage"
ON public.user_memory FOR ALL
TO authenticated
USING (auth.uid()::text = user_id)
WITH CHECK (auth.uid()::text = user_id);

-- Fix RLS for chat_history
DROP POLICY IF EXISTS "chat_history_manage" ON public.chat_history;
CREATE POLICY "chat_history_manage"
ON public.chat_history FOR ALL
TO authenticated
USING (auth.uid()::text = user_id)
WITH CHECK (auth.uid()::text = user_id);
