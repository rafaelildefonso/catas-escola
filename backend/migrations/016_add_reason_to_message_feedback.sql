-- =========================================================
-- Migration 016: Add reason column to message_feedback
-- Description: Adiciona o campo 'reason' para capturar o motivo
--              do feedback (like/dislike) com opções específicas.
-- =========================================================

-- Adicionar coluna reason (texto curto para motivo do feedback)
ALTER TABLE message_feedback
ADD COLUMN IF NOT EXISTS reason TEXT;

-- Criar índice para queries por reason (analytics)
CREATE INDEX IF NOT EXISTS idx_feedback_reason ON message_feedback (reason);

-- Comentário para documentação
COMMENT ON COLUMN message_feedback.reason IS 'Motivo do feedback (ex: clearAnswer, automationFailed, etc.)';

-- Atualizar trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION public.update_feedback_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_message_feedback_modtime ON message_feedback;
CREATE TRIGGER update_message_feedback_modtime
BEFORE UPDATE ON message_feedback
FOR EACH ROW EXECUTE FUNCTION public.update_feedback_updated_at();