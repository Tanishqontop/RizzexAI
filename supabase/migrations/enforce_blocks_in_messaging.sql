-- Prevent blocked users from sending messages to each other.

CREATE OR REPLACE FUNCTION public.users_are_blocked(user_a UUID, user_b UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.blocks
    WHERE (blocker_id = user_a AND blocked_id = user_b)
       OR (blocker_id = user_b AND blocked_id = user_a)
  );
$$;

REVOKE ALL ON FUNCTION public.users_are_blocked(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.users_are_blocked(UUID, UUID) TO authenticated;

DROP POLICY IF EXISTS "Match participants can send messages" ON public.messages;

CREATE POLICY "Match participants can send messages"
    ON public.messages FOR INSERT
    WITH CHECK (
        auth.uid() = sender_id
        AND EXISTS (
            SELECT 1
            FROM public.matches
            WHERE matches.id = messages.match_id
              AND (matches.user1_id = auth.uid() OR matches.user2_id = auth.uid())
              AND NOT public.users_are_blocked(
                auth.uid(),
                CASE
                  WHEN matches.user1_id = auth.uid() THEN matches.user2_id
                  ELSE matches.user1_id
                END
              )
        )
    );
