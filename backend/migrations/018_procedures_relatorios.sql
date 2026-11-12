-- =========================================================
-- CATAS - MIGRATION 018: Procedures de Relatórios e Busca (MySQL)
-- =========================================================
-- Funcionalidades além do CRUD básico (WHERE, ORDER BY,
-- JOIN, GROUP BY, agregações, busca textual e paginação).
-- O repositório (backend/repositories) chama estas funções
-- quando o banco for MySQL.
-- Rode este script no MySQL Workbench.

-- ---------------------------------------------------------------------------
-- 1) fn_dashboard_estatisticas
--    Estatísticas agregadas para o Dashboard (retorna JSON).
-- ---------------------------------------------------------------------------
DELIMITER $$

CREATE FUNCTION fn_dashboard_estatisticas(
    p_user_id VARCHAR(36),
    p_dias INT
)
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_corte DATETIME;
    DECLARE v_total_execucoes INT;
    DECLARE v_taxa INT;
    DECLARE v_duracao DOUBLE;
    DECLARE v_total_sessoes INT;
    DECLARE v_total_mensagens INT;
    DECLARE v_por_status JSON;
    DECLARE v_por_dia JSON;
    DECLARE v_top_integracoes JSON;

    IF p_dias IS NULL THEN
        SET p_dias = 7;
    END IF;
    SET v_corte = DATE_SUB(NOW(), INTERVAL p_dias DAY);

    SELECT COUNT(*) INTO v_total_execucoes
    FROM automation_runs ar
    WHERE ar.user_id = p_user_id AND ar.created_at >= v_corte;

    SELECT COALESCE(
        ROUND(100.0 * SUM(CASE WHEN ar.status = 'completed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)),
        0
    ) INTO v_taxa
    FROM automation_runs ar
    WHERE ar.user_id = p_user_id AND ar.created_at >= v_corte;

    SELECT AVG(TIMESTAMPDIFF(SECOND, ar.started_at, ar.finished_at))
    INTO v_duracao
    FROM automation_runs ar
    WHERE ar.user_id = p_user_id
      AND ar.created_at >= v_corte
      AND ar.finished_at IS NOT NULL;

    SELECT COALESCE(
        JSON_OBJECTAGG(status, qtd),
        JSON_OBJECT()
    ) INTO v_por_status
    FROM (
        SELECT ar.status AS status, COUNT(*) AS qtd
        FROM automation_runs ar
        WHERE ar.user_id = p_user_id AND ar.created_at >= v_corte
        GROUP BY ar.status
    ) st;

    SELECT COALESCE(
        JSON_ARRAYAGG(
            JSON_OBJECT('dia', DATE_FORMAT(d.dia, '%Y-%m-%d'), 'total', d.total)
        ),
        JSON_ARRAY()
    ) INTO v_por_dia
    FROM (
        SELECT DATE(ar.created_at) AS dia, COUNT(*) AS total
        FROM automation_runs ar
        WHERE ar.user_id = p_user_id AND ar.created_at >= v_corte
        GROUP BY DATE(ar.created_at)
        ORDER BY dia
    ) d;

    SELECT COALESCE(
        JSON_ARRAYAGG(
            JSON_OBJECT('provider', i.provider, 'total', i.qtd)
        ),
        JSON_ARRAY()
    ) INTO v_top_integracoes
    FROM (
        SELECT ig.provider AS provider, COUNT(*) AS qtd
        FROM integrations ig
        WHERE ig.user_id = p_user_id AND ig.is_connected = 1
        GROUP BY ig.provider
        ORDER BY qtd DESC
        LIMIT 5
    ) i;

    SELECT COUNT(*) INTO v_total_sessoes
    FROM chat_sessions cs
    WHERE cs.user_id = p_user_id;

    SELECT COUNT(*) INTO v_total_mensagens
    FROM messages m
    JOIN chat_sessions cs ON cs.id = m.session_id
    WHERE cs.user_id = p_user_id;

    RETURN JSON_OBJECT(
        'total_execucoes', v_total_execucoes,
        'taxa_sucesso', v_taxa,
        'duracao_media_segundos', v_duracao,
        'execucoes_por_status', v_por_status,
        'execucoes_por_dia', v_por_dia,
        'top_integracoes', v_top_integracoes,
        'total_sessoes_chat', v_total_sessoes,
        'total_mensagens_chat', v_total_mensagens
    );
END$$

-- ---------------------------------------------------------------------------
-- 2) fn_relatorio_automacoes
--    Relatório paginado de execuções de automação com JOIN na definição
--    (automations), filtros por status/período/busca, ordenação dinâmica
--    e contagem total via window function (COUNT(*) OVER()).
--    PROCEDURE (MySQL) — retorna o result set via CALL.
-- ---------------------------------------------------------------------------
CREATE PROCEDURE fn_relatorio_automacoes(
    IN p_user_id VARCHAR(36),
    IN p_status VARCHAR(255),
    IN p_data_inicio DATETIME,
    IN p_data_fim DATETIME,
    IN p_busca VARCHAR(255),
    IN p_ordem VARCHAR(20),
    IN p_limite INT,
    IN p_deslocamento INT
)
BEGIN
    DECLARE v_ordem VARCHAR(20);

    -- Whitelist para evitar injeção na ordenação
    SET v_ordem = CASE
        WHEN p_ordem IN ('created_at', 'updated_at', 'started_at', 'status', 'run_type')
        THEN p_ordem
        ELSE 'created_at'
    END;

    SET @sql_rel = CONCAT(
        'SELECT ar.id, ar.user_id, ar.automation_id, a.name AS automation_name,
                ar.status, ar.run_type, ar.input_summary,
                ar.created_at, ar.started_at, ar.finished_at,
                COUNT(*) OVER() AS total
        FROM automation_runs ar
        LEFT JOIN automations a ON a.id = ar.automation_id
        WHERE ar.user_id = ''',
        p_user_id, '''
          AND (? IS NULL OR ar.status = ?)
          AND (? IS NULL OR ar.created_at >= ?)
          AND (? IS NULL OR ar.created_at <= ?)
          AND (? IS NULL OR ar.input_summary LIKE ? OR a.name LIKE ? OR a.description LIKE ?)
        ORDER BY ar.', v_ordem, ' ASC, ar.created_at DESC
        LIMIT ', CAST(p_limite AS CHAR), ' OFFSET ', CAST(p_deslocamento AS CHAR)
    );

    SET @p_status = p_status;
    SET @p_ini = p_data_inicio;
    SET @p_fim = p_data_fim;
    SET @busca = CASE WHEN p_busca IS NULL THEN NULL ELSE CONCAT('%', p_busca, '%') END;

    PREPARE stmt_rel FROM @sql_rel;
    EXECUTE stmt_rel
        USING @p_status, @p_status, @p_ini, @p_ini, @p_fim, @p_fim,
              @busca, @busca, @busca, @busca;
    DEALLOCATE PREPARE stmt_rel;
END$$

-- ---------------------------------------------------------------------------
-- 3) fn_relatorio_chat
--    Resumo de conversas/mensagens/feedback (retorna JSON).
-- ---------------------------------------------------------------------------
CREATE FUNCTION fn_relatorio_chat(
    p_user_id VARCHAR(36),
    p_dias INT
)
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_corte DATETIME;
    DECLARE v_total_sessoes INT;
    DECLARE v_total_mensagens INT;
    DECLARE v_sessoes_ativas INT;
    DECLARE v_por_role JSON;
    DECLARE v_por_dia JSON;
    DECLARE v_feedback JSON;
    DECLARE v_likes INT;
    DECLARE v_dislikes INT;

    IF p_dias IS NULL THEN
        SET p_dias = 30;
    END IF;
    SET v_corte = DATE_SUB(NOW(), INTERVAL p_dias DAY);

    SELECT COUNT(*) INTO v_total_sessoes
    FROM chat_sessions
    WHERE user_id = p_user_id;

    SELECT COUNT(*) INTO v_total_mensagens
    FROM messages m
    JOIN chat_sessions cs ON cs.id = m.session_id
    WHERE cs.user_id = p_user_id AND m.created_at >= v_corte;

    SELECT COUNT(DISTINCT cs.id) INTO v_sessoes_ativas
    FROM messages m
    JOIN chat_sessions cs ON cs.id = m.session_id
    WHERE cs.user_id = p_user_id AND m.created_at >= v_corte;

    SELECT COALESCE(
        JSON_OBJECTAGG(m.role, qtd),
        JSON_OBJECT()
    ) INTO v_por_role
    FROM (
        SELECT m.role AS role, COUNT(*) AS qtd
        FROM messages m
        JOIN chat_sessions cs ON cs.id = m.session_id
        WHERE cs.user_id = p_user_id AND m.created_at >= v_corte
        GROUP BY m.role
    ) m;

    SELECT COALESCE(
        JSON_ARRAYAGG(
            JSON_OBJECT(
                'dia', DATE_FORMAT(d.dia, '%Y-%m-%d'),
                'usuarios', d.usuarios,
                'assistentes', d.assistentes
            )
        ),
        JSON_ARRAY()
    ) INTO v_por_dia
    FROM (
        SELECT DATE(m.created_at) AS dia,
               SUM(CASE WHEN m.role = 'user' THEN 1 ELSE 0 END) AS usuarios,
               SUM(CASE WHEN m.role = 'assistant' THEN 1 ELSE 0 END) AS assistentes
        FROM messages m
        JOIN chat_sessions cs ON cs.id = m.session_id
        WHERE cs.user_id = p_user_id AND m.created_at >= v_corte
        GROUP BY DATE(m.created_at)
        ORDER BY dia
    ) d;

    SELECT COALESCE(SUM(CASE WHEN fb.is_liked = 1 THEN 1 ELSE 0 END), 0),
           COALESCE(SUM(CASE WHEN fb.is_liked = 0 THEN 1 ELSE 0 END), 0)
    INTO v_likes, v_dislikes
    FROM message_feedback fb
    WHERE fb.user_id = p_user_id AND fb.created_at >= v_corte;

    SET v_feedback = JSON_OBJECT('likes', v_likes, 'dislikes', v_dislikes);

    RETURN JSON_OBJECT(
        'total_sessoes', v_total_sessoes,
        'total_mensagens', v_total_mensagens,
        'sessoes_ativas', v_sessoes_ativas,
        'mensagens_por_role', v_por_role,
        'mensagens_por_dia', v_por_dia,
        'feedback', v_feedback
    );
END$$

-- ---------------------------------------------------------------------------
-- 4) fn_buscar_mensagens
--    Busca textual (LIKE) no conteúdo das mensagens e no título da sessão,
--    com JOIN em chat_sessions e paginação (COUNT(*) OVER()).
--    PROCEDURE (MySQL) — retorna o result set via CALL.
-- ---------------------------------------------------------------------------
CREATE PROCEDURE fn_buscar_mensagens(
    IN p_user_id VARCHAR(36),
    IN p_termo VARCHAR(255),
    IN p_limite INT,
    IN p_deslocamento INT
)
BEGIN
    IF p_limite IS NULL THEN
        SET p_limite = 50;
    END IF;
    IF p_deslocamento IS NULL THEN
        SET p_deslocamento = 0;
    END IF;

    SET @termo = CONCAT('%', p_termo, '%');

    SELECT m.id, m.session_id, cs.title AS session_title, m.role, m.content, m.created_at,
           COUNT(*) OVER() AS total
    FROM messages m
    JOIN chat_sessions cs ON cs.id = m.session_id
    WHERE cs.user_id = p_user_id
      AND (m.content LIKE @termo OR cs.title LIKE @termo)
    ORDER BY m.created_at DESC
    LIMIT p_limite OFFSET p_deslocamento;
END$$

DELIMITER ;
