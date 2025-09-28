-- Add comprehensive profile fields for onboarding data
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS first_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS age INTEGER;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS gender_visible_on_profile BOOLEAN DEFAULT true;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS sexuality TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS looking_for TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS location_city TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS location_state TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS location_country TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS latitude DECIMAL;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS longitude DECIMAL;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS height_feet INTEGER;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS height_inches INTEGER;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS ethnicity TEXT[];
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS religious_belief TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS political_belief TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS education_level TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS school_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS work_company TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS job_title TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS drinking TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS smoking_tobacco TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS smoking_weed TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS drug_use TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS wants_children TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS has_children TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS zodiac_sign TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS profile_photos TEXT[];
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS onboarding_step INTEGER DEFAULT 0;

-- Add indexes for common queries
CREATE INDEX IF NOT EXISTS profiles_age_idx ON profiles(age);
CREATE INDEX IF NOT EXISTS profiles_gender_idx ON profiles(gender);
CREATE INDEX IF NOT EXISTS profiles_location_idx ON profiles(location_city, location_state);
CREATE INDEX IF NOT EXISTS profiles_onboarding_completed_idx ON profiles(onboarding_completed);

-- Update the updated_at timestamp when any field changes
CREATE OR REPLACE FUNCTION update_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Ensure the trigger exists
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_profiles_updated_at();
