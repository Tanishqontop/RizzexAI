-- Create a function to handle battle joining atomically
CREATE OR REPLACE FUNCTION join_battle(
    p_battle_id UUID,
    p_player2_id UUID,
    p_player2_line TEXT,
    p_voting_ends_at TIMESTAMPTZ,
    p_updated_at TIMESTAMPTZ
) RETURNS UUID AS $$
DECLARE
    v_battle_id UUID;
    v_current_status TEXT;
    v_current_player2_id UUID;
    v_current_player1_id UUID;
    v_error_message TEXT;
BEGIN
    -- Get current battle state for debugging
    SELECT status, player2_id, player1_id 
    INTO v_current_status, v_current_player2_id, v_current_player1_id
    FROM battles 
    WHERE id = p_battle_id;

    -- Log the current state
    RAISE NOTICE 'Attempting to join battle: %', p_battle_id;
    RAISE NOTICE 'Current status: %', v_current_status;
    RAISE NOTICE 'Current player2_id: %', v_current_player2_id;
    RAISE NOTICE 'Current player1_id: %', v_current_player1_id;
    RAISE NOTICE 'New player2_id: %', p_player2_id;

    -- Validate conditions
    IF v_current_status IS NULL THEN
        RAISE NOTICE 'Battle not found';
        RETURN NULL;
    END IF;

    IF v_current_status != 'waiting' THEN
        RAISE NOTICE 'Battle is not in waiting status';
        RETURN NULL;
    END IF;

    IF v_current_player2_id IS NOT NULL THEN
        RAISE NOTICE 'Battle already has a player 2';
        RETURN NULL;
    END IF;

    IF v_current_player1_id = p_player2_id THEN
        RAISE NOTICE 'Player cannot join their own battle';
        RETURN NULL;
    END IF;

    -- Update the battle
    BEGIN
        UPDATE battles
        SET 
            player2_id = p_player2_id,
            player2_line = p_player2_line,
            status = 'active',
            voting_ends_at = p_voting_ends_at,
            updated_at = p_updated_at
        WHERE 
            id = p_battle_id
            AND status = 'waiting'
            AND player2_id IS NULL
            AND player1_id != p_player2_id
        RETURNING id INTO v_battle_id;

        IF v_battle_id IS NULL THEN
            RAISE NOTICE 'Update failed - no rows affected';
            RETURN NULL;
        END IF;

        RAISE NOTICE 'Update successful - battle joined';
        RETURN v_battle_id;
    EXCEPTION WHEN OTHERS THEN
        v_error_message := SQLERRM;
        RAISE NOTICE 'Error during update: %', v_error_message;
        RETURN NULL;
    END;
END;
$$ LANGUAGE plpgsql; 