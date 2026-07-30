-- Compliments: 2 per day per user; reply creates a match

CREATE TABLE IF NOT EXISTS compliments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    reply TEXT,
    replied_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    CHECK (sender_id <> recipient_id)
);

CREATE INDEX IF NOT EXISTS compliments_sender_id_idx ON compliments(sender_id);
CREATE INDEX IF NOT EXISTS compliments_recipient_id_idx ON compliments(recipient_id);
CREATE INDEX IF NOT EXISTS compliments_created_at_idx ON compliments(created_at);

ALTER TABLE compliments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can send compliments"
    ON compliments FOR INSERT
    WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can read compliments they sent or received"
    ON compliments FOR SELECT
    USING (auth.uid() = sender_id OR auth.uid() = recipient_id);

CREATE POLICY "Recipients can reply to pending compliments"
    ON compliments FOR UPDATE
    USING (auth.uid() = recipient_id AND reply IS NULL)
    WITH CHECK (auth.uid() = recipient_id);
