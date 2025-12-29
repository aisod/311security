-- Check if storage buckets exist in Supabase
-- Run this in Supabase SQL Editor to verify bucket status

-- =============================================================================
-- BUCKET VERIFICATION
-- =============================================================================

-- Check if the 3 required buckets exist
SELECT 
  id,
  name,
  public,
  file_size_limit,
  pg_size_pretty(file_size_limit::bigint) as size_limit_formatted,
  allowed_mime_types,
  created_at,
  updated_at,
  CASE 
    WHEN id IN ('avatars', 'crime-evidence', 'notification-images') THEN '✅ REQUIRED'
    ELSE '❓ OTHER'
  END as status
FROM storage.buckets
ORDER BY 
  CASE 
    WHEN id = 'avatars' THEN 1
    WHEN id = 'crime-evidence' THEN 2
    WHEN id = 'notification-images' THEN 3
    ELSE 4
  END;

-- =============================================================================
-- DETAILED BUCKET CHECK
-- =============================================================================

-- Show which required buckets are missing
SELECT 
  bucket_name,
  CASE 
    WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = bucket_name) THEN '✅ EXISTS'
    ELSE '❌ MISSING'
  END as status,
  CASE 
    WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = bucket_name) 
    THEN (SELECT public FROM storage.buckets WHERE id = bucket_name)
    ELSE NULL
  END as is_public,
  CASE 
    WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = bucket_name) 
    THEN pg_size_pretty((SELECT file_size_limit FROM storage.buckets WHERE id = bucket_name)::bigint)
    ELSE NULL
  END as size_limit
FROM (
  VALUES 
    ('avatars'),
    ('crime-evidence'),
    ('notification-images')
) AS required_buckets(bucket_name);

-- =============================================================================
-- BUCKET POLICIES CHECK
-- =============================================================================

-- Check policies for storage.objects table
SELECT 
  policyname,
  cmd as operation,
  CASE 
    WHEN roles = '{public}' THEN 'public'
    WHEN roles = '{authenticated}' THEN 'authenticated'
    ELSE roles::text
  END as roles,
  CASE 
    WHEN policyname LIKE '%avatar%' THEN 'avatars'
    WHEN policyname LIKE '%evidence%' THEN 'crime-evidence'
    WHEN policyname LIKE '%notification%' THEN 'notification-images'
    ELSE 'other'
  END as bucket_category
FROM pg_policies
WHERE tablename = 'objects'
  AND schemaname = 'storage'
ORDER BY bucket_category, cmd;

-- =============================================================================
-- STORAGE USAGE STATISTICS
-- =============================================================================

-- Show current storage usage by bucket
SELECT 
  COALESCE(bucket_id, 'TOTAL') as bucket,
  COUNT(*) as file_count,
  pg_size_pretty(SUM(COALESCE((metadata->>'size')::bigint, 0))) as total_size,
  SUM(COALESCE((metadata->>'size')::bigint, 0)) as bytes
FROM storage.objects
WHERE bucket_id IN ('avatars', 'crime-evidence', 'notification-images')
GROUP BY ROLLUP(bucket_id)
ORDER BY 
  CASE bucket
    WHEN 'avatars' THEN 1
    WHEN 'crime-evidence' THEN 2
    WHEN 'notification-images' THEN 3
    WHEN 'TOTAL' THEN 4
    ELSE 5
  END;

-- =============================================================================
-- SUMMARY REPORT
-- =============================================================================

-- Final summary
WITH bucket_check AS (
  SELECT 
    COUNT(*) FILTER (WHERE id IN ('avatars', 'crime-evidence', 'notification-images')) as existing_count,
    3 as required_count
  FROM storage.buckets
),
policy_check AS (
  SELECT COUNT(*) as policy_count
  FROM pg_policies
  WHERE tablename = 'objects'
    AND schemaname = 'storage'
    AND (
      policyname LIKE '%avatar%' OR 
      policyname LIKE '%evidence%' OR 
      policyname LIKE '%notification%'
    )
)
SELECT 
  '📊 STORAGE STATUS REPORT' as report_section,
  TO_CHAR(NOW(), 'YYYY-MM-DD HH24:MI:SS') as generated_at,
  CONCAT(bc.existing_count, ' / ', bc.required_count) as buckets_status,
  CASE 
    WHEN bc.existing_count = bc.required_count THEN '✅ ALL BUCKETS EXIST'
    WHEN bc.existing_count = 0 THEN '❌ NO BUCKETS FOUND'
    ELSE '⚠️ SOME BUCKETS MISSING'
  END as bucket_result,
  pc.policy_count as policies_configured,
  CASE 
    WHEN pc.policy_count >= 10 THEN '✅ POLICIES CONFIGURED'
    WHEN pc.policy_count > 0 THEN '⚠️ PARTIAL POLICIES'
    ELSE '❌ NO POLICIES'
  END as policy_result
FROM bucket_check bc, policy_check pc;

