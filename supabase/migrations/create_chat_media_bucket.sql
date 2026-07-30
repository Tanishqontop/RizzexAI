-- Chat photo storage bucket + policies
-- Run this in Supabase SQL Editor if chat photo uploads fail with "Bucket not found".

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'chat_media',
    'chat_media',
    true,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Upload: path is {match_id}/{user_id}/{filename}
DROP POLICY IF EXISTS "Chat media upload by match participants" ON storage.objects;
CREATE POLICY "Chat media upload by match participants"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'chat_media'
        AND (storage.foldername(name))[2] = auth.uid()::text
        AND EXISTS (
            SELECT 1 FROM matches
            WHERE matches.id::text = (storage.foldername(name))[1]
            AND (matches.user1_id = auth.uid() OR matches.user2_id = auth.uid())
        )
    );

-- Read: any authenticated user in the match can view chat media
DROP POLICY IF EXISTS "Chat media read by match participants" ON storage.objects;
CREATE POLICY "Chat media read by match participants"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'chat_media'
        AND EXISTS (
            SELECT 1 FROM matches
            WHERE matches.id::text = (storage.foldername(name))[1]
            AND (matches.user1_id = auth.uid() OR matches.user2_id = auth.uid())
        )
    );

-- Update/delete: uploader or any match participant (view-once consume)
DROP POLICY IF EXISTS "Chat media delete own uploads" ON storage.objects;
CREATE POLICY "Chat media delete own uploads"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'chat_media'
        AND (storage.foldername(name))[2] = auth.uid()::text
    );

DROP POLICY IF EXISTS "Chat media delete by match participants" ON storage.objects;
CREATE POLICY "Chat media delete by match participants"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'chat_media'
        AND EXISTS (
            SELECT 1 FROM matches
            WHERE matches.id::text = (storage.foldername(name))[1]
            AND (matches.user1_id = auth.uid() OR matches.user2_id = auth.uid())
        )
    );
