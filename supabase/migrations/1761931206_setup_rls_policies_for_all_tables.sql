-- Migration: setup_rls_policies_for_all_tables
-- Created at: 1761931206

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE crime_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ========== PROFILES TABLE POLICIES ==========
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
CREATE POLICY "Users can read own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can read all user profiles" ON profiles;
CREATE POLICY "Admins can read all user profiles" ON profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p 
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "Super admins can manage all profiles" ON profiles;
CREATE POLICY "Super admins can manage all profiles" ON profiles
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles p 
      WHERE p.id = auth.uid() AND p.role = 'super_admin'
    )
  );

-- ========== CRIME REPORTS TABLE POLICIES ==========
DROP POLICY IF EXISTS "Users can read own reports" ON crime_reports;
CREATE POLICY "Users can read own reports" ON crime_reports
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create reports" ON crime_reports;
CREATE POLICY "Users can create reports" ON crime_reports
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can read all reports" ON crime_reports;
CREATE POLICY "Admins can read all reports" ON crime_reports
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p 
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "Admins can update reports" ON crime_reports;
CREATE POLICY "Admins can update reports" ON crime_reports
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles p 
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'super_admin')
    )
  );

-- ========== EMERGENCY ALERTS TABLE POLICIES ==========
DROP POLICY IF EXISTS "Users can read own alerts" ON emergency_alerts;
CREATE POLICY "Users can read own alerts" ON emergency_alerts
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create alerts" ON emergency_alerts;
CREATE POLICY "Users can create alerts" ON emergency_alerts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can read all alerts" ON emergency_alerts;
CREATE POLICY "Admins can read all alerts" ON emergency_alerts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p 
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "Admins can update alerts" ON emergency_alerts;
CREATE POLICY "Admins can update alerts" ON emergency_alerts
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles p 
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'super_admin')
    )
  );

-- ========== SAFETY ALERTS TABLE POLICIES ==========
DROP POLICY IF EXISTS "Everyone can read active alerts" ON safety_alerts;
CREATE POLICY "Everyone can read active alerts" ON safety_alerts
  FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Admins can create alerts" ON safety_alerts;
CREATE POLICY "Admins can create alerts" ON safety_alerts
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p 
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "Admins can update alerts" ON safety_alerts;
CREATE POLICY "Admins can update alerts" ON safety_alerts
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles p 
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'super_admin')
    )
  );

-- ========== EMERGENCY CONTACTS TABLE POLICIES ==========
DROP POLICY IF EXISTS "Users can manage own contacts" ON emergency_contacts;
CREATE POLICY "Users can manage own contacts" ON emergency_contacts
  FOR ALL USING (auth.uid() = user_id);

-- ========== NOTIFICATIONS TABLE POLICIES ==========
DROP POLICY IF EXISTS "Users can manage own notifications" ON notifications;
CREATE POLICY "Users can manage own notifications" ON notifications
  FOR ALL USING (auth.uid() = user_id);;