-- Fix swipes RLS: allow reading incoming likes and updating own swipes

DROP POLICY IF EXISTS "Users can read their own swipes" ON swipes;

CREATE POLICY "Users can read relevant swipes"
    ON swipes FOR SELECT
    USING (auth.uid() = swiper_id OR auth.uid() = target_id);

CREATE POLICY "Users can update their own swipes"
    ON swipes FOR UPDATE
    USING (auth.uid() = swiper_id)
    WITH CHECK (auth.uid() = swiper_id);
