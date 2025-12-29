-- Fix profiles table policies to allow insertion during signup
-- Created at: 2025-11-19

-- Ensure users can INSERT their own profile
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Ensure users can SELECT their own profile (already exists but good to confirm)
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
CREATE POLICY "Users can read own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

-- Ensure users can UPDATE their own profile (already exists but good to confirm)
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Add columns for ID information if they don't exist
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS id_number TEXT,
ADD COLUMN IF NOT EXISTS id_type TEXT;

-- Add status column to crime_reports for admin approval workflow
ALTER TABLE crime_reports
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';

-- Allow public read access to APPROVED crime reports
-- This replaces the "Users can read own reports" policy with a broader one
DROP POLICY IF EXISTS "Users can read own reports" ON crime_reports;
DROP POLICY IF EXISTS "Public can read approved reports" ON crime_reports;

CREATE POLICY "Public can read approved reports" ON crime_reports
  FOR SELECT USING (
    -- Users can see their own reports regardless of status
    auth.uid() = user_id 
    OR 
    -- Everyone can see approved reports
    status = 'approved'
  );

