-- pgvector + ia_memory (RAG) — embedding dim 1536 (OpenAI text-embedding-3-small / ada-002 family)

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS public.ia_memory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  key text NOT NULL DEFAULT 'user_preference',
  content text NOT NULL,
  embedding vector(1536),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ia_memory_user_created
  ON public.ia_memory(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ia_memory_metadata_gin
  ON public.ia_memory USING gin (metadata);

-- Create IVFFLAT/HNSW on embedding after bulk load (see docs/arquitetura/banco-dados.md)

ALTER TABLE public.ia_memory ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ia_memory_manage" ON public.ia_memory;
CREATE POLICY "ia_memory_manage"
ON public.ia_memory FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Semantic search: only for the authenticated user (SECURITY DEFINER + auth.uid check)
CREATE OR REPLACE FUNCTION public.match_ia_memory(
  query_embedding vector(1536),
  match_user uuid,
  match_count integer DEFAULT 8
)
RETURNS TABLE (
  id uuid,
  key text,
  content text,
  similarity double precision
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Com JWT de usuário: só o próprio user_id. Com service_role, auth.uid() é null — permitido (backend).
  IF auth.uid() IS NOT NULL AND auth.uid() IS DISTINCT FROM match_user THEN
    RETURN;
  END IF;
  RETURN QUERY
  SELECT
    im.id,
    im.key,
    im.content,
    (1 - (im.embedding <=> query_embedding))::double precision AS similarity
  FROM public.ia_memory im
  WHERE im.user_id = match_user
    AND im.embedding IS NOT NULL
  ORDER BY im.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.match_ia_memory(vector(1536), uuid, integer) TO authenticated;

COMMENT ON TABLE public.ia_memory IS 'Memória semântica por usuário (RAG / pgvector)';
