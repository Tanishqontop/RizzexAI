-- Block, report, and account deletion for Play Store safety requirements

CREATE TABLE IF NOT EXISTS blocks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE (blocker_id, blocked_id),
    CHECK (blocker_id <> blocked_id)
);

CREATE INDEX IF NOT EXISTS blocks_blocker_id_idx ON blocks(blocker_id);
CREATE INDEX IF NOT EXISTS blocks_blocked_id_idx ON blocks(blocked_id);

CREATE TABLE IF NOT EXISTS reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reported_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    details TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    CHECK (reporter_id <> reported_id)
);

CREATE INDEX IF NOT EXISTS reports_reporter_id_idx ON reports(reporter_id);
CREATE INDEX IF NOT EXISTS reports_reported_id_idx ON reports(reported_id);

ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can block others"
    ON blocks FOR INSERT
    WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Users can read their blocks"
    ON blocks FOR SELECT
    USING (auth.uid() = blocker_id);

CREATE POLICY "Users can unblock"
    ON blocks FOR DELETE
    USING (auth.uid() = blocker_id);

CREATE POLICY "Users can submit reports"
    ON reports FOR INSERT
    WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Users can read their own reports"
    ON reports FOR SELECT
    USING (auth.uid() = reporter_id);

-- Deletes the authenticated user's auth record and cascaded app data.
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    uid UUID := auth.uid();
BEGIN
    IF uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    DELETE FROM auth.users WHERE id = uid;
END;
$$;

REVOKE ALL ON FUNCTION delete_user_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION delete_user_account() TO authenticated;
