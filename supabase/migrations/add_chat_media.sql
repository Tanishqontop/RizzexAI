-- Chat media: images + view-once support

ALTER TABLE messages
    ADD COLUMN IF NOT EXISTS message_type TEXT NOT NULL DEFAULT 'text'
        CHECK (message_type IN ('text', 'image')),
    ADD COLUMN IF NOT EXISTS media_url TEXT,
    ADD COLUMN IF NOT EXISTS view_once BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS viewed_at TIMESTAMPTZ;

-- Image messages may have an optional caption in content; allow empty text payloads.
ALTER TABLE messages ALTER COLUMN content SET DEFAULT '';

CREATE INDEX IF NOT EXISTS messages_message_type_idx ON messages(message_type);

CREATE POLICY "Recipients can mark view-once messages as viewed"
    ON messages FOR UPDATE
    USING (
        view_once = true
        AND viewed_at IS NULL
        AND sender_id <> auth.uid()
        AND EXISTS (
            SELECT 1 FROM matches
            WHERE matches.id = messages.match_id
            AND (matches.user1_id = auth.uid() OR matches.user2_id = auth.uid())
        )
    )
    WITH CHECK (
        sender_id = sender_id
        AND view_once = true
        AND viewed_at IS NOT NULL
    );

-- Storage bucket + policies: run create_chat_media_bucket.sql in Supabase SQL Editor.
