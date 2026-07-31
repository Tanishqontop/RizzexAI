-- Allow users to rewind swipes and undo matches created from their likes

CREATE POLICY "Users can delete their own swipes"
    ON swipes FOR DELETE
    USING (auth.uid() = swiper_id);

CREATE POLICY "Users can delete their matches"
    ON matches FOR DELETE
    USING (auth.uid() = user1_id OR auth.uid() = user2_id);
