-- View-once: storage delete + message consume (run after add_chat_media.sql)
-- Run in Supabase SQL Editor if view-once photos are not deleted after opening.

-- Allow match participants to delete chat media (recipient deletes on view-once open)
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

-- Recipients clearing media_url when marking view-once as viewed
DROP POLICY IF EXISTS "Recipients can mark view-once messages as viewed" ON messages;
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
        AND media_url IS NULL
    );

-- Atomic consume: delete storage file + mark message viewed (bypasses RLS edge cases)
CREATE OR REPLACE FUNCTION public.consume_view_once_message(p_message_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, storage
AS $$
DECLARE
  v_message public.messages%ROWTYPE;
  v_storage_path TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_message
  FROM public.messages
  WHERE id = p_message_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Message not found';
  END IF;

  IF NOT v_message.view_once OR v_message.viewed_at IS NOT NULL THEN
    RETURN;
  END IF;

  IF v_message.sender_id = auth.uid() THEN
    RAISE EXCEPTION 'Sender cannot consume view-once message';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.matches m
    WHERE m.id = v_message.match_id
      AND (m.user1_id = auth.uid() OR m.user2_id = auth.uid())
  ) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  IF v_message.media_url IS NOT NULL AND v_message.media_url <> '' THEN
    IF v_message.media_url LIKE '%/storage/v1/object/public/chat_media/%' THEN
      v_storage_path := substring(
        v_message.media_url FROM '.*/storage/v1/object/public/chat_media/(.*)$'
      );
    ELSIF v_message.media_url LIKE '%/storage/v1/object/chat_media/%' THEN
      v_storage_path := split_part(
        substring(v_message.media_url FROM '.*/storage/v1/object/chat_media/(.+)$'),
        '?',
        1
      );
    END IF;

    IF v_storage_path IS NOT NULL AND v_storage_path <> '' THEN
      DELETE FROM storage.objects
      WHERE bucket_id = 'chat_media'
        AND name = v_storage_path;
    END IF;
  END IF;

  UPDATE public.messages
  SET viewed_at = TIMEZONE('utc'::text, NOW()),
      media_url = NULL
  WHERE id = p_message_id;
END;
$$;

REVOKE ALL ON FUNCTION public.consume_view_once_message(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.consume_view_once_message(UUID) TO authenticated;
