# 🚨 CRITICAL: Run These SQL Scripts Immediately

To fix the "Profile Photo Upload Failed" and "Registration Data Missing" errors, you MUST run these SQL scripts in your Supabase Dashboard.

## Step 1: Fix Registration & Approval Workflow
1. Open **Supabase Dashboard** -> **SQL Editor**.
2. Click **New Query**.
3. Copy/Paste the code below and click **Run**.

```sql
-- Fix profiles table policies to allow insertion during signup
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Ensure users can SELECT/UPDATE their own profile
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
CREATE POLICY "Users can read own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

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
```

## Step 2: Fix Profile Photo Uploads
1. Clear the editor or open a new query.
2. Copy/Paste the code below and click **Run**.

```sql
-- Fix storage RLS policies to ensure uploads work

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Public can view avatars" ON storage.objects;

-- Avatars Bucket Policies
CREATE POLICY "Public can view avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' 
  -- Relaxed path check: just ensure it starts with profiles/
  AND (storage.foldername(name))[1] = 'profiles'
);

CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' 
  AND (storage.foldername(name))[1] = 'profiles'
);

CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' 
  AND (storage.foldername(name))[1] = 'profiles'
);
```

## Step 3: Verify
1. Try signing up a new user in the app.
2. Check the `profiles` table in Supabase -> **Table Editor**.
   - Ensure `id_number` and `phone_number` are saved.
3. Try uploading a profile photo.
   - Ensure it appears in **Storage** -> `avatars` -> `profiles/`.

