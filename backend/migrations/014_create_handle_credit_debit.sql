-- =========================================================
-- CATAS - MIGRATION 014: handle_credit_debit (MySQL)
-- =========================================================
-- Esta função debita créditos do usuário de forma atômica,
-- usando a cota mensal primeiro e depois o rollover.
-- Adaptada de PL/pgSQL para MySQL.

DELIMITER $$

CREATE FUNCTION handle_credit_debit(
    p_user_id VARCHAR(36),
    p_amount INT
)
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_monthly_remaining INT;
    DECLARE v_deduct_from_monthly INT;
    DECLARE v_deduct_from_rollover INT;
    DECLARE v_new_monthly_used INT;
    DECLARE v_new_rollover_balance INT;
    DECLARE v_monthly_limit INT;
    DECLARE v_quota_used INT;
    DECLARE v_rollover_credits INT;
    DECLARE v_plan VARCHAR(255);

    -- Buscar perfil com lock
    SELECT monthly_quota_limit, quota_used, rollover_credits, subscription_tier
    INTO v_monthly_limit, v_quota_used, v_rollover_credits, v_plan
    FROM profiles
    WHERE id = p_user_id
    FOR UPDATE;

    -- Perfil não encontrado
    IF v_monthly_limit IS NULL THEN
        RETURN JSON_OBJECT(
            'status', 'error',
            'message', 'User profile not found'
        );
    END IF;

    -- Créditos mensais restantes
    SET v_monthly_remaining = GREATEST(0, v_monthly_limit - v_quota_used);

    -- Determinar quanto debitar de cada pool
    IF v_monthly_remaining >= p_amount THEN
        SET v_deduct_from_monthly = p_amount;
        SET v_deduct_from_rollover = 0;
    ELSE
        SET v_deduct_from_monthly = v_monthly_remaining;
        SET v_deduct_from_rollover = p_amount - v_monthly_remaining;
    END IF;

    -- Verificar créditos totais suficientes
    IF (v_monthly_remaining + COALESCE(v_rollover_credits, 0)) < p_amount THEN
        RETURN JSON_OBJECT(
            'status', 'error',
            'message', 'Insufficient credits',
            'monthly_remaining', v_monthly_remaining,
            'rollover_available', COALESCE(v_rollover_credits, 0),
            'requested', p_amount
        );
    END IF;

    -- Novos saldos
    SET v_new_monthly_used = v_quota_used + v_deduct_from_monthly;
    SET v_new_rollover_balance = GREATEST(0, COALESCE(v_rollover_credits, 0) - v_deduct_from_rollover);

    -- Atualizar perfil
    UPDATE profiles
    SET quota_used = v_new_monthly_used,
        rollover_credits = v_new_rollover_balance,
        updated_at = NOW()
    WHERE id = p_user_id;

    -- Sucesso
    RETURN JSON_OBJECT(
        'status', 'success',
        'amount_debited', p_amount,
        'deducted_from_monthly', v_deduct_from_monthly,
        'deducted_from_rollover', v_deduct_from_rollover,
        'new_monthly_used', v_new_monthly_used,
        'monthly_limit', v_monthly_limit,
        'new_rollover_balance', v_new_rollover_balance
    );
END$$

DELIMITER ;