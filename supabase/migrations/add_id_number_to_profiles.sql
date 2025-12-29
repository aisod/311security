-- Add id_number and id_type columns to profiles table
-- Migration: Add ID number fields for better admin visibility

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS id_number TEXT,
ADD COLUMN IF NOT EXISTS id_type TEXT CHECK (id_type IN ('namibianId', 'passport'));

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_profiles_id_number ON profiles(id_number) WHERE id_number IS NOT NULL;

-- Migrate existing data from metadata to direct columns
UPDATE profiles
SET 
  id_number = (metadata->>'id_number')::TEXT,
  id_type = (metadata->>'id_type')::TEXT
WHERE metadata IS NOT NULL 
  AND (metadata->>'id_number') IS NOT NULL
  AND (id_number IS NULL OR id_type IS NULL);

COMMENT ON COLUMN profiles.id_number IS 'User ID number (Namibian ID or Passport)';
COMMENT ON COLUMN profiles.id_type IS 'Type of ID: namibianId or passport';

