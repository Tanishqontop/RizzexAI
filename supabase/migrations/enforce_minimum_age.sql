-- Server-side 18+ enforcement on profiles (complements Flutter AgeValidator).

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_minimum_age_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_minimum_age_check
  CHECK (
    date_of_birth IS NULL
    OR date_of_birth <= (CURRENT_DATE - INTERVAL '18 years')
  );

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_age_minimum_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_age_minimum_check
  CHECK (age IS NULL OR age >= 18);

CREATE OR REPLACE FUNCTION public.enforce_profile_minimum_age()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.date_of_birth IS NOT NULL THEN
    IF NEW.date_of_birth > (CURRENT_DATE - INTERVAL '18 years') THEN
      RAISE EXCEPTION
        USING MESSAGE = 'RizzexAI is available only to users aged 18 and above.';
    END IF;

    NEW.age := DATE_PART(
      'year',
      AGE(CURRENT_DATE, NEW.date_of_birth)
    )::INTEGER;
  ELSIF NEW.age IS NOT NULL AND NEW.age < 18 THEN
    RAISE EXCEPTION
      USING MESSAGE = 'RizzexAI is available only to users aged 18 and above.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_profile_minimum_age_trigger ON public.profiles;

CREATE TRIGGER enforce_profile_minimum_age_trigger
  BEFORE INSERT OR UPDATE OF date_of_birth, age
  ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_profile_minimum_age();
