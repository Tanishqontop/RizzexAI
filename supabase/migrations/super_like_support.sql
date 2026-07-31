-- Super Likes: stored as action = 'super_like' on swipes table.
-- Recipients can read incoming swipes via fix_swipes_rls.sql policy.
-- Weekly limit (2 per user) is enforced in the app via SuperLikeService.

CREATE INDEX IF NOT EXISTS swipes_super_like_target_idx
    ON swipes (target_id, created_at DESC)
    WHERE action = 'super_like';

CREATE INDEX IF NOT EXISTS swipes_super_like_swiper_week_idx
    ON swipes (swiper_id, created_at DESC)
    WHERE action = 'super_like';
