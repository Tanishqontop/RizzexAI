-- Required for in-app block: remove match + idempotent block upserts.

DROP POLICY IF EXISTS "Match participants can delete their matches" ON public.matches;
CREATE POLICY "Match participants can delete their matches"
    ON public.matches FOR DELETE
    USING (auth.uid() = user1_id OR auth.uid() = user2_id);

DROP POLICY IF EXISTS "Users can update their blocks" ON public.blocks;
CREATE POLICY "Users can update their blocks"
    ON public.blocks FOR UPDATE
    USING (auth.uid() = blocker_id)
    WITH CHECK (auth.uid() = blocker_id);

-- Lets either party hide the other in chat/feed when a block exists.
DROP POLICY IF EXISTS "Users can read their blocks" ON public.blocks;
DROP POLICY IF EXISTS "Users can read blocks targeting them" ON public.blocks;
CREATE POLICY "Users can read blocks targeting them"
    ON public.blocks FOR SELECT
    USING (auth.uid() = blocker_id OR auth.uid() = blocked_id);
