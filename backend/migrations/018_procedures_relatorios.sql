-- =========================================================
-- CATAS - MIGRATION 018: Procedures de Relatórios e Busca
-- =========================================================
-- Funcionalidades além do CRUD básico (WHERE, ORDER BY,
-- JOIN, GROUP BY, agregações, busca textual e paginação).
-- Repositorio (backend/app/repositories) chama estas
-- procedures quando o banco for PostgreSQL (Supabase).
-- Rode este script no Editor SQL do seu projeto Supabase.

-- ---------------------------------------------------------------------------
-- 1) fn_dashboard_estatisticas
--    Estatísticas agregadas para o Dashboard:
--    - total de execuções de automação no período
--    - taxa de sucesso e duração média
--    - execuções por status e por dia
--    - top integrações conectadas
--    - total de sessões e mensagens de chat
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_dashboard_estatisticas(
    p_user_id uuid,
    p_dias integer DEFAULT 7
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_corte timestamptz := now() - make_interval(days => p_dias);
    v_resultado jsonb;
BEGIN
    SELECT jsonb_build_object(
        'total_execucoes', (
            SELECT COUNT(*)::integer
            FROM public.automation_runs ar
            WHERE ar.user_id = p_user_id AND ar.created_at >= v_corte
        ),
        'taxa_sucesso', (
            SELECT COALESCE(
                ROUND(
                    100.0 * COUNT(*) FILTER (WHERE ar.status = 'completed')
                    / NULLIF(COUNT(*), 0)
                ),
                0
            )::integer
            FROM public.automation_runs ar
            WHERE ar.user_id = p_user_id AND ar.created_at >= v_corte
        ),
        'duracao_media_segundos', (
            SELECT ROUND(AVG(EXTRACT(EPOCH FROM (elapsed.finished_at - elapsed.started_at)))::numeric, 1)
            FROM public.automation_runs elapsed
            WHERE elapsed.user_id = p_user_id
              AND elapsed.created_at >= v_corte
              AND elapsed.finished_at IS NOT NULL
        ),
        'execucoes_por_status', (
            SELECT COALESCE(
                jsonb_object_agg(status, qtd),
                '{}'::jsonb
            )
            FROM (
                SELECT status, COUNT(*)::integer AS qtd
                FROM public.automation_runs ar
                WHERE ar.user_id = p_user_id AND ar.created_at >= v_corte
                GROUP BY status
            ) st
        ),
        'execucoes_por_dia', (
            SELECT COALESCE(
                jsonb_agg(
                    jsonb_build_object(
                        'dia', to_char(d.dia, 'YYYY-MM-DD'),
                        'total', d.total
                    )
                    ORDER BY d.dia
                ),
                '[]'::jsonb
            )
            FROM (
                SELECT date_trunc('day', ar.created_at) AS dia,
                       COUNT(*)::integer AS total
                FROM public.automation_runs ar
                WHERE ar.user_id = p_user_id AND ar.created_at >= v_corte
                GROUP BY date_trunc('day', ar.created_at)
            ) d
        ),
        'top_integracoes', (
            SELECT COALESCE(
                jsonb_agg(
                    jsonb_build_object('provider', i.provider, 'total', i.qtd)
                    ORDER BY i.qtd DESC
                ),
                '[]'::jsonb
            )
            FROM (
                SELECT provider, COUNT(*)::integer AS qtd
                FROM public.integrations ig
                WHERE ig.user_id = p_user_id
                GROUP BY provider
                ORDER BY qtd DESC
                LIMIT 5
            ) i
        ),
        'total_sessoes_chat', (
            SELECT COUNT(*)::integer
            FROM public.chat_sessions cs
            WHERE cs.user_id = p_user_id
        ),
        'total_mensagens_chat', (
            SELECT COUNT(*)::integer
            FROM public.messages m
            JOIN public.chat_sessions cs ON cs.id = m.session_id
            WHERE cs.user_id = p_user_id
        )
    ) INTO v_resultado;

    RETURN v_resultado;
END;
$$;

COMMENT ON FUNCTION public.fn_dashboard_estatisticas(uuid, integer) IS
'Estatísticas agregadas do dashboard em um único JSONB.';

-- ---------------------------------------------------------------------------
-- 2) fn_relatorio_automacoes
--    Relatório paginado de execuções de automação com JOIN na definição
--    (automations), filtros por status/período/busca, ordenação dinâmica
--    e contagem total via window function (COUNT(*) OVER()).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_relatorio_automacoes(
    p_user_id uuid,
    p_status text DEFAULT NULL,
    p_data_inicio timestamptz DEFAULT NULL,
    p_data_fim timestamptz DEFAULT NULL,
    p_busca text DEFAULT NULL,
    p_ordem text DEFAULT 'created_at',
    p_limite integer DEFAULT 50,
    p_deslocamento integer DEFAULT 0
)
RETURNS TABLE (
    id uuid,
    user_id uuid,
    automation_id uuid,
    automation_name text,
    status text,
    run_type text,
    input_summary text,
    created_at timestamptz,
    started_at timestamptz,
    finished_at timestamptz,
    total bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_ordem text;
BEGIN
    -- Whitelist para evitar injeção por parametrização de coluna
    v_ordem := CASE
        WHEN p_ordem IN ('created_at', 'updated_at', 'started_at', 'status', 'run_type')
        THEN p_ordem
        ELSE 'created_at'
    END;

    RETURN QUERY EXECUTE format(
        $sql$
        SELECT ar.id, ar.user_id, ar.automation_id, a.name,
               ar.status, ar.run_type, ar.input_summary,
               ar.created_at, ar.started_at, ar.finished_at,
               COUNT(*) OVER()::bigint AS total
        FROM public.automation_runs ar
        LEFT JOIN public.automations a ON a.id = ar.automation_id
        WHERE ar.user_id = $1
          AND ($2::text IS NULL OR ar.status = $2)
          AND ($3::timestamptz IS NULL OR ar.created_at >= $3)
          AND ($4::timestamptz IS NULL OR ar.created_at <= $4)
          AND ($5::text IS NULL
               OR ar.input_summary ILIKE '%%' || $5 || '%%'
               OR a.name ILIKE '%%' || $5 || '%%'
               OR a.description ILIKE '%%' || $5 || '%%')
        ORDER BY ar.%I ASC, ar.created_at DESC
        LIMIT $6 OFFSET $7
        $sql,
        v_ordem
    )
    USING p_user_id, p_status, p_data_inicio, p_data_fim, p_busca, p_limite, p_deslocamento;
END;
$$;

COMMENT ON FUNCTION public.fn_relatorio_automacoes(uuid, text, timestamptz, timestamptz, text, text, integer, integer) IS
    'Relatório paginado de execuções de automação com JOIN, filtros e ordenação.';

-- ---------------------------------------------------------------------------
-- 3) fn_relatorio_chat
--    Relatório de conversas: totais, mensagens por role e por dia e
--    feedback (likes/dislikes), com JOIN entre chat_sessions e messages.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_relatorio_chat(
    p_user_id uuid,
    p_dias integer DEFAULT 30
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_corte timestamptz := now() - make_interval(days => p_dias);
    v_mensagens_por_dia jsonb;
    v_feedback jsonb;
    v_resultado jsonb;
BEGIN
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'dia', to_char(d.dia, 'YYYY-MM-DD'),
                'sessoes', d.sessoes,
                'usuarios', d.usuarios,
                'assistentes', d.assistentes
            )
            ORDER BY d.dia
        ),
        '[]'::jsonb
    ) INTO v_mensagens_por_dia
    FROM (
        SELECT date_trunc('day', m.created_at) AS dia,
               COUNT(*) FILTER (WHERE m.role = 'user')   AS sessoes,
               COUNT(*) FILTER (WHERE m.role = 'assistant') AS assistentes,
               COUNT(*) FILTER (WHERE m.role = 'system')   AS sessoes,
               COUNT(*) AS total_mensagens
        FROM public.messages m
        JOIN public.chat_sessions cs ON cs.id = m.session_id
        WHERE cs.user_id = p_user_id AND m.created_at >= v_corte
        GROUP BY date_trunc('day', m.created_at)
    ) d;

    SELECT jsonb_build_object(
        'likes',   COUNT(*) FILTER (WHERE fb.is_liked),
        'dislikes', COUNT(*) FILTER (WHERE NOT fb.is_liked)
    ) INTO v_feedback
    FROM public.message_feedback fb
    WHERE fb.user_id = p_user_id AND fb.created_at >= v_corte;

    SELECT jsonb_build_object(
        'total_sessoes', (
            SELECT COUNT(*)::integer
            FROM public.chat_sessions cs
            WHERE cs.user_id = p_user_id
        ),
        'total_mensagens', (
            SELECT COUNT(*)::integer
            FROM public.messages m
            JOIN public.chat_sessions cs ON cs.id = m.session_id
            WHERE cs.user_id = p_user_id AND m.created_at >= v_corte
        ),
        'sessoes_ativas', (
            SELECT COUNT(DISTINCT cs.id)::integer
            FROM public.messages m
            JOIN public.chat_sessions cs ON cs.id = m.session_id
            WHERE cs.user_id = p_user_id AND m.created_at >= v_corte
        ),
        'mensagens_por_role', (
            SELECT COALESCE(
                jsonb_object_agg(m.role, qtd),
                '{}'::jsonb
            )
            FROM (
                SELECT m.role, COUNT(*)::integer AS qtd
                FROM public.messages m
                JOIN public.chat_sessions cs ON cs.id = m.session_id
                WHERE cs.user_id = p_user_id
                  AND m.created_at >= v_corte
                GROUP BY m.role
            ) m
        ),
        'mensagens_por_dia', v_mensagens_por_dia,
        'feedback', v_feedback
    ) INTO v_resultado;

    RETURN v_resultado;
END;
$$;

COMMENT ON FUNCTION public.fn_relatorio_chat(uuid, integer) IS
    'Resumo de conversas, mensagens e feedback do chat no período.';

-- ---------------------------------------------------------------------------
-- 4) fn_buscar_mensagens
--    Busca textual (ILIKE) no conteúdo das mensagens e no título da sessão,
--    com JOIN em chat_sessions e paginação (COUNT(*) OVER()).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_buscar_mensagens(
    p_user_id uuid,
    p_termo text,
    p_limite integer DEFAULT 50,
    p_deslocamento integer DEFAULT 0
)
RETURNS TABLE (
    id uuid,
    session_id uuid,
    session_title text,
    role text,
    content text,
    created_at timestamptz,
    total bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT m.id, m.session_id, cs.title, m.role, m.content, m.created_at,
           COUNT(*) OVER()::bigint AS total
    FROM public.messages m
    JOIN public.chat_sessions cs ON cs.id = m.session_id
    WHERE cs.user_id = p_user_id
      AND (m.content ILIKE '%%' || p_termo || '%%'
           OR cs.title ILIKE '%%' || p_termo || '%%')
    ORDER BY m.created_at DESC
    LIMIT p_limite OFFSET p_deslocamento;
END;
$$;

COMMENT ON FUNCTION public.fn_buscar_mensagens(uuid, text, integer, integer) IS
    'Busca textual em mensagens do usuário com JOIN de sessão.';