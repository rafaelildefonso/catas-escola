-- Migration: 009_create_message_feedback
-- Cria a tabela para armazenar o feedback (like/dislike) das respostas da IA.
-- O objetivo é aprender quais tipos de resposta o usuário prefere.

CREATE TABLE IF NOT EXISTS message_feedback (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id   UUID NOT NULL,          -- ID da mensagem na tabela `messages`
    user_id      UUID NOT NULL,          -- Quem deu o feedback
    session_id   UUID NOT NULL,          -- Sessão da mensagem (para queries analíticas)
    is_liked     BOOLEAN NOT NULL,       -- true = like, false = dislike
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Garante um feedback por mensagem por usuário
    CONSTRAINT uq_feedback_message_user UNIQUE (message_id, user_id)
);

-- Índices para queries analíticas rápidas
CREATE INDEX IF NOT EXISTS idx_feedback_user_id    ON message_feedback (user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_session_id ON message_feedback (session_id);
CREATE INDEX IF NOT EXISTS idx_feedback_is_liked   ON message_feedback (is_liked);
CREATE INDEX IF NOT EXISTS idx_feedback_created_at ON message_feedback (created_at DESC);

-- RLS: usuários só veem/manipulam seus próprios feedbacks
ALTER TABLE message_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own feedback"
    ON message_feedback FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own feedback"
    ON message_feedback FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own feedback"
    ON message_feedback FOR DELETE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can select own feedback"
    ON message_feedback FOR SELECT
    USING (auth.uid() = user_id);

-- Service-role ignora RLS automaticamente (o backend usa service_role key).
