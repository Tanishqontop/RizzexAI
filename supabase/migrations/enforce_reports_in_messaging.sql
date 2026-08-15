-- Reports are private to the reporter for feed/chat hiding.
-- Messaging is blocked between a reporter and the user they reported.

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
  )
  OR EXISTS (
    SELECT 1
    FROM public.reports
    WHERE (reporter_id = user_a AND reported_id = user_b)
       OR (reporter_id = user_b AND reported_id = user_a)
  );
$$;

REVOKE ALL ON FUNCTION public.users_are_blocked(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.users_are_blocked(UUID, UUID) TO authenticated;
