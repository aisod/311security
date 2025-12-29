-- Create storage buckets for 3:11 Security User App
-- Run this in Supabase SQL Editor or via migration

-- =============================================================================
-- STORAGE BUCKETS
-- =============================================================================

-- 1. Create avatars bucket for profile images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];

-- 2. Create crime-evidence bucket for evidence photos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'crime-evidence',
  'crime-evidence',
  true,
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];

-- 3. Create notification-images bucket for notification attachments
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'notification-images',
  'notification-images',
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];

-- =============================================================================
-- STORAGE POLICIES
-- =============================================================================

-- -------------------------
-- AVATARS BUCKET POLICIES
-- -------------------------

-- Allow authenticated users to upload their own avatars
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = 'profiles'
);

-- Allow authenticated users to update their own avatars
CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = 'profiles'
);

-- Allow authenticated users to delete their own avatars
CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = 'profiles'
);

-- Allow public read access to avatars
CREATE POLICY "Public can view avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- -------------------------
-- CRIME-EVIDENCE BUCKET POLICIES
-- -------------------------

-- Allow authenticated users to upload evidence
CREATE POLICY "Authenticated users can upload evidence"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'crime-evidence' AND
  (storage.foldername(name))[1] = 'evidence'
);

-- Allow authenticated users to view evidence
CREATE POLICY "Authenticated users can view evidence"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'crime-evidence');

-- Allow admins to view all evidence
CREATE POLICY "Admins can view all evidence"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'crime-evidence' AND
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('admin', 'super_admin')
  )
);

-- Allow admins to delete evidence if needed
CREATE POLICY "Admins can delete evidence"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'crime-evidence' AND
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('admin', 'super_admin')
  )
);

-- -------------------------
-- NOTIFICATION-IMAGES BUCKET POLICIES
-- -------------------------

-- Allow admins to upload notification images
CREATE POLICY "Admins can upload notification images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'notification-images' AND
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('admin', 'super_admin')
  )
);

-- Allow admins to update notification images
CREATE POLICY "Admins can update notification images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'notification-images' AND
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('admin', 'super_admin')
  )
);

-- Allow admins to delete notification images
CREATE POLICY "Admins can delete notification images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'notification-images' AND
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('admin', 'super_admin')
  )
);

-- Allow public read access to notification images
CREATE POLICY "Public can view notification images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'notification-images');

-- =============================================================================
-- VERIFICATION
-- =============================================================================

-- Verify buckets were created
SELECT id, name, public, file_size_limit, allowed_mime_types, created_at
FROM storage.buckets
WHERE id IN ('avatars', 'crime-evidence', 'notification-images')
ORDER BY created_at;

-- Verify policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'objects'
AND policyname LIKE '%avatar%' OR policyname LIKE '%evidence%' OR policyname LIKE '%notification%'
ORDER BY policyname;

