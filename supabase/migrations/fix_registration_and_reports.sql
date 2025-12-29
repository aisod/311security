-- =============================================================================
-- FIX 1: REGISTRATION DATA & APPROVAL WORKFLOW
-- =============================================================================

-- 1. Allow users to INSERT their own profile data during signup
--    This fixes the "missing ID/Phone number" issue.
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
--    This prevents errors if these columns are missing.
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS id_number TEXT,
ADD COLUMN IF NOT EXISTS id_type TEXT;

-- 5. Add status column to crime_reports for admin approval
--    Default is 'pending' so new reports aren't public immediately.
ALTER TABLE crime_reports
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';

-- 6. Update permissions: Public can ONLY read 'approved' reports
--    Users can always see their own reports.
DROP POLICY IF EXISTS "Users can read own reports" ON crime_reports;
DROP POLICY IF EXISTS "Public can read approved reports" ON crime_reports;

CREATE POLICY "Public can read approved reports" ON crime_reports
  FOR SELECT USING (
    -- Users can see their own reports regardless of status
    auth.uid() = user_id 
    OR 
    -- Everyone else can ONLY see approved reports
    status = 'approved'
  );

