-- Complete account deletion: storage, app data, and Supabase Auth user.
-- Profile media paths: profile_media/{user_id}/{filename}
-- Chat media paths:     chat_media/{match_id}/{user_id}/{filename}
--
-- Safe to retry: missing Storage rows do not cause failures.

-- Drop any existing profiles -> auth.users FK (name may vary in older DBs).
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT c.conname
    FROM pg_constraint c
    JOIN pg_class rel ON rel.oid = c.conrelid
    JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
    WHERE nsp.nspname = 'public'
      AND rel.relname = 'profiles'
      AND c.contype = 'f'
      AND c.confrelid = 'auth.users'::regclass
  LOOP
    EXECUTE format(
      'ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS %I',
      r.conname
    );
  END LOOP;
END $$;

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_id_fkey;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint c
    JOIN pg_class rel ON rel.oid = c.conrelid
    JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
    WHERE nsp.nspname = 'public'
      AND rel.relname = 'profiles'
      AND c.conname = 'profiles_id_fkey'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_id_fkey
      FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

DO $$
DECLARE
  r RECORD;
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'player_stats'
  ) THEN
    FOR r IN
      SELECT c.conname
      FROM pg_constraint c
      JOIN pg_class rel ON rel.oid = c.conrelid
      JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
      WHERE nsp.nspname = 'public'
        AND rel.relname = 'player_stats'
        AND c.contype = 'f'
        AND c.confrelid = 'auth.users'::regclass
    LOOP
      EXECUTE format(
        'ALTER TABLE public.player_stats DROP CONSTRAINT IF EXISTS %I',
        r.conname
      );
    END LOOP;

    ALTER TABLE public.player_stats
      DROP CONSTRAINT IF EXISTS player_stats_user_id_fkey;

    IF NOT EXISTS (
      SELECT 1
      FROM pg_constraint c
      JOIN pg_class rel ON rel.oid = c.conrelid
      JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
      WHERE nsp.nspname = 'public'
        AND rel.relname = 'player_stats'
        AND c.conname = 'player_stats_user_id_fkey'
    ) THEN
      ALTER TABLE public.player_stats
        ADD CONSTRAINT player_stats_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

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

  -- 1) Profile photos/videos: {user_id}/{filename}
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

  -- 2) Chat images uploaded by the user: {match_id}/{user_id}/{filename}
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

  -- 3) Legacy tables without auth.users FK (if present).
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

  -- 4) Explicit profile cleanup before auth delete.
  DELETE FROM public.profiles WHERE id = uid;

  -- 5) Delete Supabase Auth account. Cascades to swipes, matches, messages,
  -- compliments, blocks, and reports.
  DELETE FROM auth.users WHERE id = uid;
END;
$$;

ALTER FUNCTION public.delete_user_account() OWNER TO postgres;

REVOKE ALL ON FUNCTION public.delete_user_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;
