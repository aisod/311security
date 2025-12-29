# Flutter App Updates Required

## 🎯 Critical Update: Registration Screen

### Issue
Your current registration screen allows users to select any role, including admin and super_admin. This is a security vulnerability.

### Solution
Modify the registration screen to force all self-registrations to use the 'user' role only.

---

## 📝 File to Modify

**Location:** `lib/screens/auth/registration_screen.dart`

### Current Code (Lines 32-34 approximately)
```dart
// ❌ REMOVE THIS - Allows users to choose admin role
final role = isAdminRegistration ? UserRole.admin : _selectedRole;
```

### Updated Code
```dart
// ✅ FORCE user role for all public registrations
final role = UserRole.user; // Citizens can only register as 'user'
```

### Complete Registration Method Update
```dart
Future<void> _handleRegistration() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // ✅ FORCE user role - no choice allowed
    final role = UserRole.user;

    // Rest of your registration logic remains the same
    await context.read<AuthProvider>().signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
      region: _selectedRegion,
      role: role, // Always 'user' for self-registration
    );

    // Navigation logic...
  } catch (e) {
    setState(() {
      _errorMessage = e.toString();
      _isLoading = false;
    });
  }
}
```

---

## 🔧 Additional UI Updates (Optional)

### Option 1: Remove Role Selection Widget Entirely
If you have a role selection dropdown or radio buttons, remove them completely:

```dart
// ❌ REMOVE role selection dropdown
DropdownButtonFormField<UserRole>(
  value: _selectedRole,
  items: [
    DropdownMenuItem(value: UserRole.user, child: Text('User')),
    DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
    DropdownMenuItem(value: UserRole.superAdmin, child: Text('Super Admin')),
  ],
  onChanged: (value) => setState(() => _selectedRole = value!),
)

// ✅ No role selection needed - just show info text
Text(
  'You are registering as a citizen user',
  style: TextStyle(color: Colors.grey),
)
```

### Option 2: Show Static Role Info
```dart
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.blue.shade50,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      Icon(Icons.info_outline, color: Colors.blue),
      SizedBox(width: 8),
      Expanded(
        child: Text(
          'You are registering as a Citizen User. Admin accounts are created by system administrators.',
          style: TextStyle(fontSize: 13),
        ),
      ),
    ],
  ),
)
```

---

## 🔐 Admin Account Creation

### For Super Admin App Only
Admin and super_admin accounts must be created using the edge function.

**Implementation Example:**
```dart
// Super Admin App - Admin Management Screen
Future<void> createAdminAccount({
  required String email,
  required String password,
  required String fullName,
  required String phoneNumber,
  String? region,
  required UserRole role, // admin or super_admin
}) async {
  try {
    final response = await Supabase.instance.client.functions.invoke(
      'create-admin-account',
      body: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'region': region,
        'role': role.value, // 'admin' or 'super_admin'
        'appType': role.value
      }
    );

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    final data = response.data['data'];
    final credentials = data['credentials'];
    
    // Display credentials to super admin
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Admin Account Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${credentials['email']}'),
            SizedBox(height: 8),
            Text('Password: ${credentials['password']}'),
            SizedBox(height: 16),
            Text(
              '⚠️ Share these credentials securely with the new admin.',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done'),
          ),
        ],
      ),
    );
  } catch (e) {
    // Handle error
    showErrorSnackBar('Failed to create admin account: $e');
  }
}
```

---

## 🧪 Testing Your Changes

### Test 1: User Self-Registration
1. Open your User App
2. Go to registration screen
3. Fill in all fields
4. Register
5. **Verify:** Check Supabase database that the new user has `role = 'user'`

### Test 2: Admin Account Creation (Super Admin Only)
1. Create a test super admin account manually in Supabase
2. Log into Super Admin App with that account
3. Use the `create-admin-account` edge function
4. **Verify:** New admin account appears in profiles table with `role = 'admin'`

### Test 3: RLS Verification
1. Log in as a regular user
2. Try to query all crime reports
3. **Expected:** Should only see own reports (RLS blocks others)
4. Log in as admin
5. Query all crime reports
6. **Expected:** Should see all reports

---

## 📋 Verification Checklist

After making these changes:

- [ ] Registration screen no longer shows role selection
- [ ] All self-registrations create 'user' role accounts
- [ ] Super admin app has admin creation interface
- [ ] Edge function `create-admin-account` works correctly
- [ ] New admin accounts receive correct credentials
- [ ] RLS policies prevent unauthorized access
- [ ] Storage buckets accept uploads
- [ ] Profile images display correctly

---

## 🚨 Security Reminder

**Never allow:**
- Users to choose admin role during registration
- Direct database writes to bypass RLS
- Hardcoded service role keys in mobile apps
- Admin credentials in plain text (except during secure handoff)

**Always ensure:**
- All user-facing registration forces 'user' role
- Admin creation goes through edge function
- Super admin credentials are protected
- RLS policies are enabled on all tables

---

## 📞 Need Help?

If you encounter issues:

1. **Check Supabase logs:** Dashboard → Logs → Edge Functions
2. **Verify RLS policies:** Dashboard → Table Editor → Policies tab
3. **Test edge functions:** Use the test tool in Supabase dashboard
4. **Review documentation:** See `docs/supabase_setup_complete.md`

Your multi-app security system is ready! 🎉
