-- Migration 002: Criação do Schema de Chat
-- Rode este script no Editor SQL do seu projeto Supabase
-- Data: 2026-02-12

-- ============================================
-- Tabela: chat_sessions
-- Armazena as sessões de conversa dos usuários
-- ============================================
CREATE TABLE IF NOT EXISTS chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT 'Nova Conversa',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para buscar sessões por usuário
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user_id ON chat_sessions(user_id);

-- Índice para ordenar por data de atualização
CREATE INDEX IF NOT EXISTS idx_chat_sessions_updated_at ON chat_sessions(updated_at DESC);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_chat_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_chat_sessions_updated_at
    BEFORE UPDATE ON chat_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_chat_sessions_updated_at();

-- ============================================
-- Tabela: messages
-- Armazena as mensagens de cada sessão
-- ============================================
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para buscar mensagens por sessão (ordenado por data)
CREATE INDEX IF NOT EXISTS idx_messages_session_id ON messages(session_id, created_at ASC);

-- Índice para buscar mensagens por role (útil para análises)
CREATE INDEX IF NOT EXISTS idx_messages_role ON messages(role);

-- Índice GIN para busca em metadata JSONB
CREATE INDEX IF NOT EXISTS idx_messages_metadata ON messages USING GIN (metadata);

-- ============================================
-- Tabela: automation_logs
-- Armazena logs de execução de automações
-- ============================================
CREATE TABLE IF NOT EXISTS automation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    intent_detected TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('success', 'failed', 'pending')),
    payload_sent JSONB NOT NULL DEFAULT '{}'::jsonb,
    response_received JSONB DEFAULT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para buscar logs por usuário
CREATE INDEX IF NOT EXISTS idx_automation_logs_user_id ON automation_logs(user_id);

-- Índice para buscar logs por status
CREATE INDEX IF NOT EXISTS idx_automation_logs_status ON automation_logs(status);

-- Índice para buscar logs por intenção
CREATE INDEX IF NOT EXISTS idx_automation_logs_intent ON automation_logs(intent_detected);

-- Índice para ordenar por data (mais recentes primeiro)
CREATE INDEX IF NOT EXISTS idx_automation_logs_created_at ON automation_logs(created_at DESC);

-- Índices GIN para busca em JSONB
CREATE INDEX IF NOT EXISTS idx_automation_logs_payload ON automation_logs USING GIN (payload_sent);
CREATE INDEX IF NOT EXISTS idx_automation_logs_response ON automation_logs USING GIN (response_received);

-- ============================================
-- Row Level Security (RLS) Policies
-- ============================================

-- Habilitar RLS nas tabelas
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE automation_logs ENABLE ROW LEVEL SECURITY;

-- Políticas para chat_sessions
-- Usuários só podem ver suas próprias sessões
CREATE POLICY "Users can view their own chat sessions"
    ON chat_sessions FOR SELECT
    USING (auth.uid() = user_id);

-- Usuários só podem criar suas próprias sessões
CREATE POLICY "Users can create their own chat sessions"
    ON chat_sessions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Usuários só podem atualizar suas próprias sessões
CREATE POLICY "Users can update their own chat sessions"
    ON chat_sessions FOR UPDATE
    USING (auth.uid() = user_id);

-- Usuários só podem deletar suas próprias sessões
CREATE POLICY "Users can delete their own chat sessions"
    ON chat_sessions FOR DELETE
    USING (auth.uid() = user_id);

-- Políticas para messages
-- Usuários só podem ver mensagens de suas próprias sessões
CREATE POLICY "Users can view messages from their own sessions"
    ON messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM chat_sessions
            WHERE chat_sessions.id = messages.session_id
            AND chat_sessions.user_id = auth.uid()
        )
    );

-- Usuários só podem criar mensagens em suas próprias sessões
CREATE POLICY "Users can create messages in their own sessions"
    ON messages FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM chat_sessions
            WHERE chat_sessions.id = messages.session_id
            AND chat_sessions.user_id = auth.uid()
        )
    );

-- Políticas para automation_logs
-- Usuários só podem ver seus próprios logs
CREATE POLICY "Users can view their own automation logs"
    ON automation_logs FOR SELECT
    USING (auth.uid() = user_id);

-- Usuários só podem criar seus próprios logs
CREATE POLICY "Users can create their own automation logs"
    ON automation_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Nota: automation_logs geralmente não são atualizados ou deletados pelos usuários,
-- mas se necessário, adicione políticas UPDATE/DELETE aqui.

-- ============================================
-- Comentários nas tabelas (documentação)
-- ============================================
COMMENT ON TABLE chat_sessions IS 'Armazena as sessões de conversa dos usuários';
COMMENT ON TABLE messages IS 'Armazena as mensagens de cada sessão de chat';
COMMENT ON TABLE automation_logs IS 'Armazena logs de execução de automações disparadas pelo sistema';

COMMENT ON COLUMN messages.role IS 'Tipo de mensagem: user, assistant ou system';
COMMENT ON COLUMN messages.metadata IS 'Metadados adicionais (ex: action_details quando uma automação é disparada)';
COMMENT ON COLUMN automation_logs.intent_detected IS 'Intenção detectada pelo sistema (ex: calendar_create_event, task_create)';
COMMENT ON COLUMN automation_logs.status IS 'Status da execução: success, failed ou pending';
