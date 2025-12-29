# Quick Setup Guide - Admin & Super Admin Apps

## 🚀 5-Minute Setup

### Prerequisites Checklist
- [ ] Flutter SDK installed (v3.6.0+)
- [ ] Git installed
- [ ] Android Studio or VS Code with Flutter extension
- [ ] Access to Supabase project

---

## Step 1: Setup Admin App (5 minutes)

```bash
# Navigate to admin app
cd security_311_admin

# Install dependencies
flutter pub get

# Create .env file
cat > .env << 'EOF'
SUPABASE_URL=https://aivxbtpeybyxaaokyxrh.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpdnhidHBleWJ5eGFhb2t5eHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MzUzNTksImV4cCI6MjA3NDExMTM1OX0.YEgLlBiiwFL8Rf6oVzDuW0aD_kPigyelxdtCsHY36x8
EOF

# Run the app
flutter run
```

---

## Step 2: Setup Super Admin App (5 minutes)

```bash
# Navigate to super admin app
cd security_311_super_admin

# Install dependencies
flutter pub get

# Create .env file
cat > .env << 'EOF'
SUPABASE_URL=https://aivxbtpeybyxaaokyxrh.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpdnhidHBleWJ5eGFhb2t5eHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MzUzNTksImV4cCI6MjA3NDExMTM1OX0.YEgLlBiiwFL8Rf6oVzDuW0aD_kPigyelxdtCsHY36x8
EOF

# Run the app
flutter run
```

---

## Step 3: Create First Super Admin Account

### Option A: Using Supabase Dashboard (Recommended)

1. **Go to Supabase Dashboard**
   - URL: https://app.supabase.com/project/aivxbtpeybyxaaokyxrh

2. **Create Auth User**
   - Navigate to: Authentication → Users
   - Click "Add user" → "Create new user"
   - Enter email: `superadmin@security.na`
   - Enter password: Choose a strong password
   - Click "Create user"
   - **Copy the user ID**

3. **Create Profile**
   - Navigate to: Table Editor → profiles
   - Click "Insert" → "Insert row"
   - Fill in:
     ```
     id: <paste user ID from step 2>
     email: superadmin@security.na
     full_name: System Administrator
     phone_number: +264811234567
     region: Khomas
     role: super_admin
     is_verified: true
     app_type: super_admin
     created_by: system
     ```
   - Click "Save"

### Option B: Using SQL

```sql
-- Step 1: Create auth user in Supabase Dashboard first
-- Then run this SQL with the auth user ID:

INSERT INTO profiles (
  id,
  email,
  full_name,
  phone_number,
  region,
  role,
  is_verified,
  app_type,
  created_by
) VALUES (
  '<auth_user_id_from_dashboard>',
  'superadmin@security.na',
  'System Administrator',
  '+264811234567',
  'Khomas',
  'super_admin',
  true,
  'super_admin',
  'system'
);
```

---

## Step 4: Login & Test

### Test Super Admin App

1. **Open Super Admin App**
2. **Login with:**
   - Email: `superadmin@security.na`
   - Password: <password you set>
3. **Verify:**
   - Dashboard loads with statistics
   - "Users" tab is visible
   - Floating "Create Admin" button appears

### Create First Admin Account

1. **In Super Admin App:**
   - Tap the "Create Admin" FAB (bottom right)
   - OR Menu → "Create Admin Account"

2. **Fill in:**
   ```
   Role: Admin
   Full Name: Police Officer
   Email: admin@police.na
   Phone: +264811234568
   Region: Khomas
   Password: Admin123!
   ```

3. **Click "Create Account"**
4. **Success!** Admin account is ready

### Test Admin App

1. **Open Admin App**
2. **Login with:**
   - Email: `admin@police.na`
   - Password: `Admin123!`
3. **Verify:**
   - Dashboard loads
   - Statistics visible
   - Can view reports and alerts

---

## Verification Checklist

### ✅ Super Admin App
- [ ] Login successful
- [ ] Dashboard shows statistics
- [ ] "Users" tab present
- [ ] "Create Admin" button visible
- [ ] Can create admin accounts
- [ ] Can view all users
- [ ] Can broadcast messages

### ✅ Admin App
- [ ] Login successful with admin credentials
- [ ] Dashboard shows statistics
- [ ] Can view crime reports
- [ ] Can view emergency alerts
- [ ] Can broadcast messages
- [ ] NO "Users" tab (correct - admin only, not super admin)

### ✅ Backend Integration
- [ ] All edge functions deployed
- [ ] RLS policies active
- [ ] Storage buckets created
- [ ] Database tables populated

---

## Common Issues & Solutions

### Issue: "Cannot find .env file"

**Solution:**
```bash
# Make sure you're in the correct directory
pwd
# Should show: .../security_311_admin or .../security_311_super_admin

# Create .env file again
cat > .env << 'EOF'
SUPABASE_URL=https://aivxbtpeybyxaaokyxrh.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpdnhidHBleWJ5eGFhb2t5eHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MzUzNTksImV4cCI6MjA3NDExMTM1OX0.YEgLlBiiwFL8Rf6oVzDuW0aD_kPigyelxdtCsHY36x8
EOF
```

### Issue: "Insufficient Permissions" after login

**Solution:**
1. Check user role in Supabase → Table Editor → profiles
2. Ensure role is `admin` for Admin App or `super_admin` for Super Admin App
3. If wrong role, update it manually in Supabase dashboard

### Issue: "Failed to create admin account"

**Solution:**
1. Verify you're logged in as super admin (not regular admin)
2. Check all form fields are filled
3. Ensure password is at least 8 characters
4. Check Supabase logs for detailed error

### Issue: Statistics not loading

**Solution:**
1. Check internet connection
2. Verify Supabase URL and key in .env
3. Ensure tables have some data
4. Check Supabase logs for errors

---

## Next Steps

### 1. Configure Apps for Your Region
- Update region list in `lib/models/namibian_regions.dart` if needed
- Customize crime types in your requirements
- Add local police station contacts

### 2. Customize Branding
- Replace app icon in `assets/images/logo.png`
- Update app names in `pubspec.yaml`
- Customize theme colors in `lib/theme.dart`

### 3. Deploy to Production
- Build release APKs
- Configure Google Maps API key for location features
- Set up push notifications
- Configure backup strategy

### 4. Train Your Team
- Share this documentation with admins
- Conduct training sessions
- Create SOPs for different scenarios
- Set up support channels

---

## Quick Reference

### Supabase Dashboard
**URL:** https://app.supabase.com/project/aivxbtpeybyxaaokyxrh

### Edge Functions
- **Create Admin:** `https://aivxbtpeybyxaaokyxrh.supabase.co/functions/v1/create-admin-account`
- **Get Profile:** `https://aivxbtpeybyxaaokyxrh.supabase.co/functions/v1/get-user-profile`
- **Update Status:** `https://aivxbtpeybyxaaokyxrh.supabase.co/functions/v1/update-user-status`

### Storage Buckets
- **Profile Images:** 5MB limit, image/*
- **Crime Evidence:** 50MB limit, image/*, video/*
- **Alert Images:** 10MB limit, image/*

### User Roles
- `user` - Regular citizens (User App)
- `admin` - Police/security (Admin App)
- `super_admin` - System admins (Super Admin App)

---

## Support

Need help? Check these resources:

1. **Documentation**
   - Full Guide: `docs/admin_super_admin_apps_guide.md`
   - Supabase Setup: `docs/supabase_setup_complete.md`
   - Flutter Updates: `docs/flutter_app_updates.md`

2. **Supabase Docs**
   - https://supabase.com/docs

3. **Flutter Docs**
   - https://docs.flutter.dev

4. **Logs**
   - Supabase Dashboard → Logs
   - Flutter: `flutter logs`

---

## Success! 🎉

You now have:
- ✅ Admin App running
- ✅ Super Admin App running
- ✅ First super admin account created
- ✅ First admin account created
- ✅ Full multi-app architecture working

**Start monitoring crime reports and keeping Namibia safe!** 🇳🇦
