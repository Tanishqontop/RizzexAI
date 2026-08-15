-- Harden in-app account deletion (run in Supabase SQL Editor if delete still fails).
-- Ensures auth.users FKs cascade, then replaces delete_user_account().

-- 1) Any public FK -> auth.users without CASCADE blocks auth deletion.
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT
      c.conname,
      c.conrelid::regclass AS tbl,
      (
        SELECT string_agg(quote_ident(a.attname), ', ' ORDER BY u.ord)
        FROM unnest(c.conkey) WITH ORDINALITY AS u(attnum, ord)
        JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = u.attnum
      ) AS col_names
    FROM pg_constraint c
    JOIN pg_class rel ON rel.oid = c.conrelid
    JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
    WHERE c.contype = 'f'
      AND c.confrelid = 'auth.users'::regclass
      AND nsp.nspname = 'public'
      AND c.confdeltype <> 'c'
  LOOP
    EXECUTE format(
      'ALTER TABLE %s DROP CONSTRAINT %I',
      r.tbl,
      r.conname
    );
    EXECUTE format(
      'ALTER TABLE %s ADD CONSTRAINT %I FOREIGN KEY (%s) REFERENCES auth.users(id) ON DELETE CASCADE',
      r.tbl,
      r.conname,
      r.col_names
    );
  END LOOP;
END $$;

-- 2) Allow users to delete their own profile row (used by RPC + optional client path).
DROP POLICY IF EXISTS "Users can delete own profile" ON public.profiles;
CREATE POLICY "Users can delete own profile"
  ON public.profiles FOR DELETE
  USING (auth.uid() = id);

-- 3) Robust deletion RPC: storage cleanup is best-effort; auth delete is required.
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, storage, auth
AS $$
DECLARE
  uid UUID := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Profile media: profile_media/{user_id}/{filename}
  BEGIN
    DELETE FROM storage.objects
    WHERE bucket_id = 'profile_media'
      AND (storage.foldername(name))[1] = uid::text;
  EXCEPTION
    WHEN undefined_table THEN NULL;
    WHEN insufficient_privilege THEN
      RAISE WARNING 'delete_user_account: profile_media cleanup skipped (permission)';
    WHEN OTHERS THEN
      RAISE WARNING 'delete_user_account: profile_media cleanup failed: %', SQLERRM;
  END;

  -- Chat media: chat_media/{match_id}/{user_id}/{filename}
  BEGIN
    DELETE FROM storage.objects
    WHERE bucket_id = 'chat_media'
      AND (storage.foldername(name))[2] = uid::text;
  EXCEPTION
    WHEN undefined_table THEN NULL;
    WHEN insufficient_privilege THEN
      RAISE WARNING 'delete_user_account: chat_media cleanup skipped (permission)';
    WHEN OTHERS THEN
      RAISE WARNING 'delete_user_account: chat_media cleanup failed: %', SQLERRM;
  END;

  IF to_regclass('public.battles') IS NOT NULL THEN
    DELETE FROM public.battles
    WHERE player1_id = uid OR player2_id = uid OR winner_id = uid;
  END IF;

  IF to_regclass('public.rizz_votes') IS NOT NULL THEN
    DELETE FROM public.rizz_votes WHERE user_id = uid;
  END IF;

  IF to_regclass('public.player_stats') IS NOT NULL THEN
    DELETE FROM public.player_stats WHERE user_id = uid;
  END IF;

  DELETE FROM public.profiles WHERE id = uid;

  DELETE FROM auth.users WHERE id = uid;
END;
$$;

ALTER FUNCTION public.delete_user_account() OWNER TO postgres;

REVOKE ALL ON FUNCTION public.delete_user_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;
