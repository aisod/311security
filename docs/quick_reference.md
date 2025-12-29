# 3:11 Security - Quick Reference Guide

## 🔑 Credentials
**Supabase URL:** `https://aivxbtpeybyxaaokyxrh.supabase.co`
**Anon Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpdnhidHBleWJ5eGFhb2t5eHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MzUzNTksImV4cCI6MjA3NDExMTM1OX0.YEgLlBiiwFL8Rf6oVzDuW0aD_kPigyelxdtCsHY36x8`

---

## 📊 Database Tables

| Table | Description | RLS Enabled |
|-------|-------------|-------------|
| **profiles** | User profiles with roles | ✅ |
| **crime_reports** | Crime incident reports | ✅ |
| **emergency_alerts** | Panic button alerts | ✅ |
| **safety_alerts** | Public announcements | ✅ |
| **emergency_contacts** | User contact lists | ✅ |
| **notifications** | In-app notifications | ✅ |

---

## 🔧 Edge Functions

### 1. Create Admin Account
**URL:** `/functions/v1/create-admin-account`
**Access:** Super admins only
```dart
await supabase.functions.invoke('create-admin-account', body: {
  'email': 'admin@example.com',
  'password': 'SecurePass123!',
  'fullName': 'Admin Name',
  'phoneNumber': '+264812345678',
  'role': 'admin' // or 'super_admin'
});
```

### 2. Get User Profile
**URL:** `/functions/v1/get-user-profile`
**Access:** Users (own profile) or admins (any profile)
```dart
await supabase.functions.invoke('get-user-profile', body: {
  'userId': 'optional-user-id' // Omit for own profile
});
```

### 3. Update User Status
**URL:** `/functions/v1/update-user-status`
**Access:** Super admins only
```dart
await supabase.functions.invoke('update-user-status', body: {
  'userId': 'target-user-id',
  'isActive': false, // Deactivate account
  'role': 'admin' // Change role (optional)
});
```

---

## 🗂️ Storage Buckets

| Bucket | Purpose | Size Limit | Types |
|--------|---------|------------|-------|
| **profile-images** | User avatars | 5 MB | JPEG, PNG, WebP |
| **crime-evidence** | Report evidence | 50 MB | Images, Videos, PDFs |
| **safety-alert-images** | Alert photos | 10 MB | JPEG, PNG, WebP |

**Upload Example:**
```dart
final file = File(imagePath);
await supabase.storage.from('profile-images').upload('path/file.jpg', file);
final url = supabase.storage.from('profile-images').getPublicUrl('path/file.jpg');
```

---

## 🔐 Role System

| Role | Access Level | Can Create |
|------|--------------|------------|
| **user** | Own data only | Crime reports, emergency alerts |
| **admin** | All reports & alerts | Safety announcements |
| **super_admin** | Full system access | Admin accounts |

---

## ⚠️ Important: Update Registration Screen

**File:** `lib/screens/auth/registration_screen.dart`

**Change Required:**
```dart
// OLD - Remove role selection dropdown
final role = _selectedRole; // ❌ Don't let users choose

// NEW - Force user role
final role = UserRole.user; // ✅ Public registration = user only
```

Only super admins can create admin accounts via the `create-admin-account` edge function.

---

## 🧪 Testing Checklist

- [ ] Verify user can self-register (user role only)
- [ ] Test crime report submission
- [ ] Test emergency alert trigger
- [ ] Test profile image upload
- [ ] Verify admin cannot self-register
- [ ] Test super admin creating admin account
- [ ] Verify RLS policies (users see only own data)
- [ ] Test admin viewing all reports

---

## 📖 Full Documentation

See **`docs/supabase_setup_complete.md`** for:
- Complete table schemas
- Detailed edge function documentation
- Security architecture
- Integration examples
- SQL verification queries
