-- Migration: fix_profiles_rls_recursion
-- Created at: 1761931207
-- Fixes infinite recursion in profiles RLS policies

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Admins can read all user profiles" ON profiles;
DROP POLICY IF EXISTS "Super admins can manage all profiles" ON profiles;

-- Create a security definer function to check user role
-- This bypasses RLS and prevents infinite recursion
CREATE OR REPLACE FUNCTION auth.user_role()
RETURNS TEXT AS $$
  SELECT role::TEXT FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Alternative: Use auth.users metadata to store role
-- For now, we'll use a function that checks without RLS recursion

-- Create fixed admin policies using a function that avoids recursion
-- We'll use a simpler approach: check role from auth metadata or use a function

-- Fix: Admins can read all profiles (but not their own - that's covered by own policy)
-- We'll use a function that checks auth metadata first
CREATE OR REPLACE FUNCTION check_is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  -- First try to get role from auth metadata (if stored there)
  -- Otherwise check profiles table with SECURITY DEFINER to avoid recursion
  RETURN EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() 
    AND role IN ('admin', 'super_admin')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Fix: Super admin check function
CREATE OR REPLACE FUNCTION check_is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() 
    AND role = 'super_admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Recreate admin policies using the functions
CREATE POLICY "Admins can read all user profiles" ON profiles
  FOR SELECT USING (
    check_is_admin()
  );

-- Super admins can manage all profiles
CREATE POLICY "Super admins can manage all profiles" ON profiles
  FOR ALL USING (
    check_is_super_admin()
  );

-- Ensure users can insert their own profile (for initial profile creation)
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

