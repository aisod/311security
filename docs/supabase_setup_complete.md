# 3:11 Security - Supabase Database Setup Complete ✅

## Overview
The multi-app security system database is now fully configured with enhanced role-based access control, supporting three app types: User App, Admin App, and Super Admin App.

---

## 📊 Database Tables Created

### 1. **profiles** (Enhanced for Multi-App)
User profiles with role-based access control
```sql
Columns:
- id (UUID, PRIMARY KEY) - References auth.users
- email (TEXT, UNIQUE)
- full_name (TEXT)
- phone_number (TEXT)
- region (TEXT)
- is_verified (BOOLEAN)
- profile_image_url (TEXT)
- role (TEXT) - 'user', 'admin', 'super_admin'
- app_type (TEXT) - App identifier
- created_by (UUID) - Admin who created the account
- is_active (BOOLEAN) - Account status
- last_login_at (TIMESTAMPTZ)
- metadata (JSONB) - Additional data
- created_at, updated_at (TIMESTAMPTZ)
```

**RLS Policies:**
- Users can read/update own profile
- Admins can read all profiles
- Super admins have full access

### 2. **crime_reports**
Crime incident reports from citizens
```sql
Columns:
- id, user_id, crime_type, title, description
- region, city, latitude, longitude, location_description
- incident_date, severity, status
- evidence_urls (TEXT[])
- is_anonymous, assigned_officer, resolution_notes
- created_at, updated_at
```

**RLS Policies:**
- Users can create and read own reports
- Admins can read/update all reports

### 3. **emergency_alerts**
Panic button and emergency activations
```sql
Columns:
- id, user_id, type (panic/medical/fire/crime_in_progress)
- description, latitude, longitude, location_description
- is_active, triggered_at, resolved_at, status
- notified_contacts, notified_services
- created_at, updated_at
```

**RLS Policies:**
- Users can create and read own alerts
- Admins can read/update all alerts

### 4. **safety_alerts**
Public safety announcements from admins
```sql
Columns:
- id, type, title, message
- region, city, latitude, longitude, location_description
- image_urls, severity, priority
- is_active, expires_at, created_by
- metadata, created_at, updated_at
```

**RLS Policies:**
- Everyone can read active alerts
- Only admins can create/update alerts

### 5. **emergency_contacts**
User emergency contact lists
```sql
Columns:
- id, user_id, name, phone_number
- relationship, priority, is_active
- notes, created_at, updated_at
```

**RLS Policies:**
- Users have full access to own contacts

### 6. **notifications**
In-app user notifications
```sql
Columns:
- id, user_id, type, title, message
- is_read, related_entity_id, related_entity_type
- metadata, action_url, created_at
```

**RLS Policies:**
- Users have full access to own notifications

---

## 🔧 Edge Functions Deployed

### 1. **create-admin-account**
**Purpose:** Allows super admins to create admin/super_admin accounts
**URL:** `https://aivxbtpeybyxaaokyxrh.supabase.co/functions/v1/create-admin-account`

**Usage:**
```javascript
const { data, error } = await supabase.functions.invoke('create-admin-account', {
  body: {
    email: 'admin@example.com',
    password: 'SecurePassword123!',
    fullName: 'John Doe',
    phoneNumber: '+264812345678',
    region: 'Khomas',
    role: 'admin', // or 'super_admin'
    appType: 'admin'
  }
});

// Returns:
// {
//   data: {
//     message: "Admin account created successfully",
//     user: { id, email, role },
//     credentials: { email, password },
//     profile: { ... }
//   }
// }
```

**Security:**
- Requires valid authentication token
- Verifies requester is super admin
- Creates auth user + profile atomically
- Rollback on failure

### 2. **get-user-profile**
**Purpose:** Fetch user profile with role-based access
**URL:** `https://aivxbtpeybyxaaokyxrh.supabase.co/functions/v1/get-user-profile`

**Usage:**
```javascript
// Get own profile
const { data, error } = await supabase.functions.invoke('get-user-profile', {
  body: {}
});

// Get another user's profile (admins only)
const { data, error } = await supabase.functions.invoke('get-user-profile', {
  body: {
    userId: 'target-user-uuid'
  }
});

// Returns: { data: { profile: { ... } } }
```

### 3. **update-user-status**
**Purpose:** Super admins can activate/deactivate accounts and update roles
**URL:** `https://aivxbtpeybyxaaokyxrh.supabase.co/functions/v1/update-user-status`

**Usage:**
```javascript
// Deactivate a user
const { data, error } = await supabase.functions.invoke('update-user-status', {
  body: {
    userId: 'target-user-uuid',
    isActive: false
  }
});

// Update user role
const { data, error } = await supabase.functions.invoke('update-user-status', {
  body: {
    userId: 'target-user-uuid',
    role: 'admin'
  }
});

// Returns: { data: { message: "...", profile: { ... } } }
```

**Security:**
- Only super admins can update accounts
- Cannot modify own account
- Updates role and/or active status

---

## 🗂️ Storage Buckets Created

### 1. **profile-images**
- **Purpose:** User profile pictures
- **Size Limit:** 5 MB
- **Allowed Types:** JPEG, PNG, WebP
- **Access:** Public

### 2. **crime-evidence**
- **Purpose:** Crime report evidence (photos, videos, documents)
- **Size Limit:** 50 MB
- **Allowed Types:** Images, Videos (MP4, QuickTime), PDFs
- **Access:** Public

### 3. **safety-alert-images**
- **Purpose:** Safety announcement images
- **Size Limit:** 10 MB
- **Allowed Types:** JPEG, PNG, WebP
- **Access:** Public

**Upload Example:**
```javascript
const { data, error } = await supabase.storage
  .from('profile-images')
  .upload(`${userId}/avatar.jpg`, file);
```

---

## 🔐 Security Architecture

### Multi-App Role System

| Role | App Type | Capabilities |
|------|----------|--------------|
| **user** | User App | Report crimes, trigger emergencies, view own data |
| **admin** | Admin App | View all reports/alerts, manage safety announcements, respond to emergencies |
| **super_admin** | Super Admin App | Full system access, create/manage admin accounts, system configuration |

### Registration Model

**✅ Allowed:**
- Citizens self-register as 'user' role
- Super admins create 'admin' and 'super_admin' accounts via edge function

**❌ Prevented:**
- Users cannot self-register as admin/super_admin
- Admins cannot elevate their own privileges
- Non-super admins cannot create admin accounts

### Row Level Security (RLS)
All tables have RLS enabled with policies enforcing:
- Users access own data only
- Admins read all operational data
- Super admins have full system access
- Public can read active safety alerts

---

## 📱 Next Steps for Flutter App

### 1. **Update App Constants**
Ensure your Flutter app has the correct Supabase credentials:

```dart
// lib/constants/app_constants.dart
static const String supabaseUrl = 'https://aivxbtpeybyxaaokyxrh.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpdnhidHBleWJ5eGFhb2t5eHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MzUzNTksImV4cCI6MjA3NDExMTM1OX0.YEgLlBiiwFL8Rf6oVzDuW0aD_kPigyelxdtCsHY36x8';
```

### 2. **Modify Registration Screen**
Remove admin/super_admin role options from user-facing registration:

```dart
// lib/screens/auth/registration_screen.dart
// Line 32-34: Remove or disable role selection
// Only allow 'user' role for self-registration

final role = UserRole.user; // Force user role for public registration
```

### 3. **Implement Edge Function Calls**

**Example: Create Admin Account (Super Admin App Only)**
```dart
final response = await Supabase.instance.client.functions.invoke(
  'create-admin-account',
  body: {
    'email': 'new.admin@example.com',
    'password': 'SecurePass123!',
    'fullName': 'Admin Name',
    'phoneNumber': '+264812345678',
    'region': 'Khomas',
    'role': 'admin',
    'appType': 'admin'
  }
);

if (response.data != null) {
  final credentials = response.data['data']['credentials'];
  // Share credentials securely with the new admin
}
```

### 4. **Storage Integration**

**Profile Image Upload:**
```dart
final file = File(imagePath);
final userId = Supabase.instance.client.auth.currentUser!.id;

final storageResponse = await Supabase.instance.client.storage
  .from('profile-images')
  .upload('$userId/avatar.jpg', file);

if (storageResponse.error == null) {
  final publicUrl = Supabase.instance.client.storage
    .from('profile-images')
    .getPublicUrl('$userId/avatar.jpg');
  
  // Update profile with image URL
  await Supabase.instance.client
    .from('profiles')
    .update({'profile_image_url': publicUrl})
    .eq('id', userId);
}
```

**Crime Evidence Upload:**
```dart
final evidenceUrls = <String>[];

for (var file in evidenceFiles) {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final fileName = '$reportId/$timestamp-${file.name}';
  
  await Supabase.instance.client.storage
    .from('crime-evidence')
    .upload(fileName, file);
  
  final publicUrl = Supabase.instance.client.storage
    .from('crime-evidence')
    .getPublicUrl(fileName);
  
  evidenceUrls.add(publicUrl);
}

// Save URLs to crime report
await Supabase.instance.client
  .from('crime_reports')
  .insert({
    'evidence_urls': evidenceUrls,
    // ... other fields
  });
```

### 5. **Test RLS Policies**

Create test accounts with different roles and verify:
- Users can only see their own data
- Admins can view all reports
- Super admins can create admin accounts
- Public registration only creates 'user' role

---

## 🎯 Architecture Highlights

### Database
✅ 6 tables with comprehensive schemas
✅ Enhanced profiles table for multi-app support
✅ Row Level Security on all tables
✅ Role-based access control
✅ Audit fields (created_by, updated_at)

### Edge Functions
✅ 3 deployed functions for admin management
✅ Secure authentication verification
✅ Role-based operation authorization
✅ Atomic operations with rollback

### Storage
✅ 3 public buckets for different media types
✅ Size limits and MIME type restrictions
✅ Ready for immediate use

### Security
✅ Hybrid registration model implemented
✅ Admin self-registration prevented
✅ Multi-tier role system (user/admin/super_admin)
✅ Database-level security (RLS)

---

## 🔍 Database Schema Verification

To verify your setup, run this query in the Supabase SQL editor:

```sql
-- Check all tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check profiles table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

---

## 🚀 System Ready

Your 3:11 Security multi-app database is fully configured and ready for integration with your Flutter apps. The system supports:

1. **User App** - Citizen crime reporting and emergency services
2. **Admin App** - Law enforcement response and management
3. **Super Admin App** - System administration and user management

All security measures, RLS policies, and edge functions are in place to ensure secure, role-based access across all three applications.

**Next:** Update your Flutter app's registration screen to remove admin role options and test the system with different user types.
