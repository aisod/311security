# 3:11 Security - Admin & Super Admin Apps

## Overview

This document provides complete information about the Admin and Super Admin applications for the 3:11 Security system.

## Architecture

The 3:11 Security system consists of three separate Flutter applications sharing the same Supabase backend:

1. **User App** (`security_311_user`) - For citizens to report crimes and emergencies
2. **Admin App** (`security_311_admin`) - For police/security personnel to monitor and respond
3. **Super Admin App** (`security_311_super_admin`) - For system administrators to manage users and admins

---

## Admin App (security_311_admin)

### Purpose
The Admin App is designed for police officers, security personnel, and emergency responders who need to monitor and respond to crime reports, emergency alerts, and safety notifications.

### Key Features
1. **Admin Dashboard**
   - System overview with real-time statistics
   - Active alerts and emergencies
   - Crime report monitoring
   - Recent activity feed

2. **Statistics & Analytics**
   - User statistics (total, verified, new users)
   - Safety alerts breakdown by type and severity
   - Crime reports by type and status
   - Emergency alerts tracking
   - Distribution charts for all categories

3. **Broadcast Messaging**
   - Send system-wide announcements
   - Alert notifications to all users
   - Emergency broadcasts
   - Information messages

4. **Report Management**
   - View all crime reports from users
   - Monitor emergency alerts
   - Track safety alerts

### Access Control
- Only users with `admin` or `super_admin` role can log in
- Cannot self-register (accounts created by super admin only)
- Role-based data access via Supabase RLS policies

### Installation & Setup

#### Prerequisites
- Flutter SDK 3.6.0 or higher
- Supabase account with configured project
- Android Studio / VS Code with Flutter extension

#### Setup Steps

1. **Navigate to Admin App Directory**
   ```bash
   cd security_311_admin
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   
   Create `.env` file in the root directory:
   ```env
   SUPABASE_URL=https://aivxbtpeybyxaaokyxrh.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpdnhidHBleWJ5eGFhb2t5eHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MzUzNTksImV4cCI6MjA3NDExMTM1OX0.YEgLlBiiwFL8Rf6oVzDuW0aD_kPigyelxdtCsHY36x8
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

### Login Credentials
Admin accounts must be created by a Super Admin. Contact your system administrator to create an admin account.

---

## Super Admin App (security_311_super_admin)

### Purpose
The Super Admin App is designed for system administrators who need full control over user management, admin account creation, and system configuration.

### Key Features

1. **All Admin Features**
   - Everything from the Admin App
   - Full access to all dashboard features
   - System statistics and monitoring

2. **User Management** (Super Admin Only)
   - View all registered users
   - Update user roles
   - Activate/deactivate accounts
   - Delete users
   - User search and filtering

3. **Admin Account Creation** (Super Admin Only)
   - Create new admin accounts
   - Create new super admin accounts
   - Set account credentials
   - Assign regions and roles
   - **Accessible via:**
     - Floating Action Button (FAB) on dashboard
     - Menu > "Create Admin Account"

4. **System Administration**
   - Monitor system health
   - View comprehensive analytics
   - Manage all security alerts
   - Full broadcast capabilities

### Access Control
- Only users with `super_admin` role can log in
- Cannot self-register (must be bootstrapped)
- Full access to all system features

### Installation & Setup

#### Prerequisites
- Flutter SDK 3.6.0 or higher
- Supabase account with configured project
- Android Studio / VS Code with Flutter extension

#### Setup Steps

1. **Navigate to Super Admin App Directory**
   ```bash
   cd security_311_super_admin
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   
   Create `.env` file in the root directory:
   ```env
   SUPABASE_URL=https://aivxbtpeybyxaaokyxrh.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpdnhidHBleWJ5eGFhb2t5eHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MzUzNTksImV4cCI6MjA3NDExMTM1OX0.YEgLlBiiwFL8Rf6oVzDuW0aD_kPigyelxdtCsHY36x8
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

### Creating First Super Admin Account

Since super admins cannot self-register, you need to create the first super admin manually in Supabase:

#### Option 1: Using Supabase Dashboard

1. Go to Supabase Dashboard → Authentication → Users
2. Create a new user with email/password
3. Copy the user ID
4. Go to Table Editor → `profiles` table
5. Insert a new row:
   ```sql
   id: <user_id_from_auth>
   email: superadmin@example.com
   full_name: System Administrator
   phone_number: +264811234567
   region: Khomas
   role: super_admin
   is_verified: true
   app_type: super_admin
   created_by: system
   ```

#### Option 2: Using SQL Editor

```sql
-- First, create the auth user (replace with your email and password)
-- This is done automatically when you create a user in Supabase Auth UI

-- Then insert the profile
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
  '<auth_user_id>',
  'superadmin@example.com',
  'System Administrator',
  '+264811234567',
  'Khomas',
  'super_admin',
  true,
  'super_admin',
  'system'
);
```

### Creating Admin Accounts

Once logged in as Super Admin:

1. **Using Floating Action Button:**
   - Tap the "Create Admin" FAB at the bottom right
   - Fill in the admin account details
   - Select role (Admin or Super Admin)
   - Submit

2. **Using Menu:**
   - Tap the menu icon (⋮) in the app bar
   - Select "Create Admin Account"
   - Fill in the details and submit

The account will be created using the Supabase Edge Function and login credentials can be shared with the new admin.

---

## Database Structure

Both apps use the same Supabase database with the following tables:

### Tables
1. **profiles** - User profiles with role-based access
2. **crime_reports** - Crime incident reports from users
3. **emergency_alerts** - Emergency/panic button activations
4. **safety_alerts** - Public safety announcements
5. **emergency_contacts** - User emergency contact lists
6. **notifications** - User notifications

### User Roles
- `user` - Regular citizens using the User App
- `admin` - Police/security personnel using the Admin App
- `super_admin` - System administrators using the Super Admin App

### Row Level Security (RLS)

All tables have RLS policies that enforce:
- **Users** can only access their own data
- **Admins** can view all reports, alerts, and user data
- **Super Admins** have full access including user management

---

## Edge Functions

### 1. create-admin-account
**URL:** `https://aivxbtpeybyxaaokyxrh.supabase.co/functions/v1/create-admin-account`

**Purpose:** Create admin or super admin accounts (Super Admin only)

**Request:**
```json
{
  "email": "admin@police.na",
  "password": "SecurePassword123",
  "full_name": "John Doe",
  "phone_number": "+264811234567",
  "role": "admin",
  "region": "Khomas"
}
```

**Response:**
```json
{
  "user": {
    "id": "uuid",
    "email": "admin@police.na"
  },
  "profile": {
    "id": "uuid",
    "full_name": "John Doe",
    "role": "admin"
  }
}
```

### 2. get-user-profile
**URL:** `https://aivxbtpeybyxaaokyxrh.supabase.co/functions/v1/get-user-profile`

**Purpose:** Fetch user profiles with role-based authorization

### 3. update-user-status
**URL:** `https://aivxbtpeybyxaaokyxrh.supabase.co/functions/v1/update-user-status`

**Purpose:** Activate/deactivate/delete user accounts (Super Admin only)

---

## Storage Buckets

### 1. profile-images
- **Size Limit:** 5MB
- **Allowed Types:** image/*
- **Purpose:** User profile pictures

### 2. crime-evidence
- **Size Limit:** 50MB
- **Allowed Types:** image/*, video/*
- **Purpose:** Crime report evidence (photos/videos)

### 3. safety-alert-images
- **Size Limit:** 10MB
- **Allowed Types:** image/*
- **Purpose:** Safety alert attachments

---

## Testing

### Test Admin Login

1. Create a test admin account using Super Admin App
2. Log in to Admin App with the credentials
3. Verify access to:
   - Dashboard with statistics
   - Crime reports list
   - Emergency alerts
   - Broadcast messaging

### Test Super Admin Login

1. Log in with super admin credentials
2. Verify access to:
   - All admin features
   - User management tab
   - Create admin account functionality
   - User role updates
   - Account deletion

---

## Troubleshooting

### Cannot Login to Admin/Super Admin App

**Problem:** "Insufficient Permissions" error after login

**Solution:**
1. Verify user role in Supabase `profiles` table
2. Ensure role is set to `admin` or `super_admin`
3. Check that RLS policies are properly configured

### Cannot Create Admin Account

**Problem:** Edge function returns error

**Solution:**
1. Verify you're logged in as super admin
2. Check Supabase logs for detailed error
3. Ensure all required fields are filled
4. Verify password meets minimum requirements (8 characters)

### Statistics Not Loading

**Problem:** Dashboard shows "Loading..." indefinitely

**Solution:**
1. Check internet connection
2. Verify Supabase configuration
3. Check if tables have data
4. Review Supabase logs for errors

---

## Best Practices

### For Admins
1. **Regular Monitoring:** Check dashboard multiple times per day
2. **Respond Promptly:** Address emergency alerts immediately
3. **Broadcast Wisely:** Use broadcast messages for important updates only
4. **Report Issues:** Contact super admin if you encounter system issues

### For Super Admins
1. **Secure Credentials:** Keep admin account credentials secure
2. **Limited Admin Creation:** Only create admin accounts for verified personnel
3. **Regular Audits:** Review user list and admin activity regularly
4. **Monitor System Health:** Check system health indicators daily
5. **Backup Strategy:** Ensure regular database backups are configured

---

## Security Considerations

### Password Security
- Minimum 8 characters for all accounts
- Recommend strong passwords with mixed characters
- Change default passwords immediately
- Never share credentials via insecure channels

### Role Assignment
- Only assign `admin` role to verified security personnel
- Only assign `super_admin` role to trusted system administrators
- Regularly review and audit role assignments

### Data Privacy
- All user data is protected by RLS policies
- Admins should only access data necessary for their duties
- Follow data protection regulations (POPIA, GDPR, etc.)

---

## Support

For technical issues or questions:
1. Check Supabase logs in Dashboard → Logs
2. Review this documentation
3. Contact system administrator
4. Check Supabase documentation: https://supabase.com/docs

---

## Changelog

### Version 1.0.0
- Initial release of Admin and Super Admin apps
- Admin dashboard with statistics
- User management for super admins
- Admin account creation
- Broadcast messaging
- Integration with Supabase backend
