-- Criação da tabela para cache de análises de página
-- Rode este script no Editor SQL do seu projeto Supabase

CREATE TABLE IF NOT EXISTS page_analysis_cache (
    url_hash TEXT PRIMARY KEY, -- Hash MD5 da URL para busca rápida
    url TEXT NOT NULL,
    analysis_result JSONB NOT NULL, -- Resultado da análise (action_cards, etc)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Índice para limpeza de cache expirado
CREATE INDEX IF NOT EXISTS idx_page_analysis_cache_expires_at ON page_analysis_cache(expires_at);
