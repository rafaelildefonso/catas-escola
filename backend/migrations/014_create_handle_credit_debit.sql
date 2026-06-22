-- =========================================================
-- CATAS - MIGRATION 014: Create handle_credit_debit RPC Function
-- =========================================================
-- Esta função debita créditos do usuário de forma atômica,
-- usando a cota mensal primeiro e depois o rollover.

CREATE OR REPLACE FUNCTION public.handle_credit_debit(
    p_user_id uuid,
    p_amount integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_profile record;
    v_monthly_remaining integer;
    v_deduct_from_monthly integer;
    v_deduct_from_rollover integer;
    v_new_monthly_used integer;
    v_new_rollover_balance integer;
    v_monthly_limit integer;
BEGIN
    -- Get user profile with lock
    SELECT 
        id,
        quota_used,
        monthly_quota_limit,
        rollover_credits,
        subscription_tier
    INTO v_profile
    FROM public.profiles
    WHERE id = p_user_id
    FOR UPDATE;
    
    -- Check if profile exists
    IF v_profile IS NULL THEN
        RETURN jsonb_build_object(
            'status', 'error',
            'message', 'User profile not found'
        );
    END IF;
    
    -- Calculate remaining monthly credits
    v_monthly_limit := COALESCE(v_profile.monthly_quota_limit, 500);
    v_monthly_remaining := GREATEST(0, v_monthly_limit - v_profile.quota_used);
    
    -- Determine how much to deduct from each pool
    IF v_monthly_remaining >= p_amount THEN
        -- Deduct all from monthly quota
        v_deduct_from_monthly := p_amount;
        v_deduct_from_rollover := 0;
    ELSE
        -- Deduct remaining monthly + rest from rollover
        v_deduct_from_monthly := v_monthly_remaining;
        v_deduct_from_rollover := p_amount - v_monthly_remaining;
    END IF;
    
    -- Check if enough total credits
    IF (v_monthly_remaining + COALESCE(v_profile.rollover_credits, 0)) < p_amount THEN
        RETURN jsonb_build_object(
            'status', 'error',
            'message', 'Insufficient credits',
            'monthly_remaining', v_monthly_remaining,
            'rollover_available', COALESCE(v_profile.rollover_credits, 0),
            'requested', p_amount
        );
    END IF;
    
    -- Calculate new balances
    v_new_monthly_used := v_profile.quota_used + v_deduct_from_monthly;
    v_new_rollover_balance := GREATEST(0, COALESCE(v_profile.rollover_credits, 0) - v_deduct_from_rollover);
    
    -- Update profile
    UPDATE public.profiles
    SET 
        quota_used = v_new_monthly_used,
        rollover_credits = v_new_rollover_balance,
        updated_at = now()
    WHERE id = p_user_id;
    
    -- Return success with details
    RETURN jsonb_build_object(
        'status', 'success',
        'amount_debited', p_amount,
        'deducted_from_monthly', v_deduct_from_monthly,
        'deducted_from_rollover', v_deduct_from_rollover,
        'new_monthly_used', v_new_monthly_used,
        'monthly_limit', v_monthly_limit,
        'new_rollover_balance', v_new_rollover_balance
    );
END;
$$;

-- Add comment for documentation
COMMENT ON FUNCTION public.handle_credit_debit(uuid, integer) IS 
'Debits credits from user account atomically. Uses monthly quota first, then rollover credits.';
