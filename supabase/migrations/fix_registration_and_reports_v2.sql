-- =============================================================================
-- FIX 1: REGISTRATION DATA & APPROVAL WORKFLOW (UPDATED)
-- =============================================================================

-- 0. ADD 'approved' TO ENUM (Fixes 22P02 error)
--    We wrap this in a transaction to safely update the type.
ALTER TYPE crime_status ADD VALUE IF NOT EXISTS 'approved';

-- 1. Allow users to INSERT their own profile data during signup
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- 2. Ensure users can SELECT their own profile
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
CREATE POLICY "Users can read own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

-- 3. Ensure users can UPDATE their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- 4. Add missing columns for ID information
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS id_number TEXT,
ADD COLUMN IF NOT EXISTS id_type TEXT;

-- 5. Add status column to crime_reports (if not exists)
--    We cast the default value to the enum type to be safe.
ALTER TABLE crime_reports
ADD COLUMN IF NOT EXISTS status crime_status DEFAULT 'pending'::crime_status;

-- 6. Update permissions: Public can ONLY read 'approved' reports
DROP POLICY IF EXISTS "Users can read own reports" ON crime_reports;
DROP POLICY IF EXISTS "Public can read approved reports" ON crime_reports;

CREATE POLICY "Public can read approved reports" ON crime_reports
  FOR SELECT USING (
    -- Users can see their own reports regardless of status
    auth.uid() = user_id 
    OR 
    -- Everyone else can ONLY see approved reports
    status = 'approved'::crime_status
  );

