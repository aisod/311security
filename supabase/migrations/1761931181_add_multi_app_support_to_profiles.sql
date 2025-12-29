-- Migration: add_multi_app_support_to_profiles
-- Created at: 1761931181

-- Add missing columns for multi-app support
ALTER TABLE profiles 
  ADD COLUMN IF NOT EXISTS app_type TEXT,
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id),
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS metadata JSONB;

-- Add check constraint for role if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'profiles_role_check'
  ) THEN
    ALTER TABLE profiles 
      ADD CONSTRAINT profiles_role_check 
      CHECK (role IN ('user', 'admin', 'super_admin'));
  END IF;
END $$;;