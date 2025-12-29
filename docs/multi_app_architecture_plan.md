# 3:11 Security Multi-App Architecture Plan

## Current App Analysis

**Great News!** Your 3:11 Security app already has the perfect foundation for a multi-app architecture:

✅ **UserRole enum** with `user`, `admin`, `super_admin` roles  
✅ **UserProfile model** with role-based access control  
✅ **RegistrationScreen** with role selection (`isAdminRegistration`)  
✅ **Supabase integration** with profiles table  
✅ **AuthService** with profile management  
✅ **Namibian regions and ID validation**  

## Multi-App System Overview

### Architecture Goals
- **Shared Supabase Database** - All apps use the same backend
- **Hybrid Registration Model** - Citizens can self-register, admins are created by super admin
- **Role-Based Access Control** - Database-level security for data separation
- **App Identification** - Each app type recognized by custom claims

### Three-App System

#### 1. **User App (Current)**
- **Purpose**: Citizens reporting crimes/emergencies
- **Registration**: Self-registration enabled (user role)
- **Access**: Limited to own data, public alerts, reporting features
- **Target Users**: General public, citizens

#### 2. **Admin App**
- **Purpose**: Police/security personnel managing reports
- **Registration**: NO self-registration - created by super admin only
- **Access**: View all user reports, manage alerts, respond to emergencies
- **Target Users**: Police officers, security personnel

#### 3. **Super Admin App**
- **Purpose**: System administrators managing everything
- **Registration**: Created by primary super admin
- **Access**: Full system control, create/manage admin accounts
- **Target Users**: System administrators, IT staff

## Database Schema Design

### Enhanced Profiles Table
```sql
-- Enhanced profiles table for multi-app support
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  region TEXT,
  is_verified BOOLEAN DEFAULT false,
  profile_image_url TEXT,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin', 'super_admin')),
  app_type TEXT, -- 'user', 'admin', 'super_admin'
  created_by TEXT, -- admin/super_admin who created this account
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  metadata JSONB -- Additional app-specific data
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for role-based access
CREATE POLICY "Users can read own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can read all user profiles" ON profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p 
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Super admins can manage all profiles" ON profiles
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles p 
      WHERE p.id = auth.uid() AND p.role = 'super_admin'
    )
  );
```

## Implementation Strategy

### Phase 1: Supabase Backend Configuration
1. **Database Schema Updates**
   - Add app_type, created_by, is_active, metadata columns
   - Implement RLS policies for multi-app access
   - Create admin management functions

2. **Edge Functions for Admin Creation**
   - `create-admin-account` - Super admin can create admin accounts
   - `get-admin-credentials` - Secure credential sharing
   - `manage-user-accounts` - User management functions

### Phase 2: User App Updates
1. **Hybrid Registration**
   - Keep self-registration for citizen accounts
   - Update UI to show role selection clearly
   - Add app identification to authentication

2. **Role-Based UI**
   - Show appropriate features based on user role
   - Implement proper error handling for unauthorized access

### Phase 3: Super Admin Web Interface
1. **Web Dashboard**
   - Admin account creation interface
   - User management panel
   - System analytics and monitoring

2. **Security Features**
   - Secure credential sharing system
   - Audit logging for admin actions
   - Account status management

### Phase 4: Admin & Super Admin Apps
1. **Admin Mobile App**
   - Police/security personnel interface
   - Crime report management
   - Emergency alert management

2. **Super Admin Mobile/Web App**
   - System administration interface
   - Full user management capabilities
   - Analytics and reporting

## Security Features

### Row Level Security (RLS)
- **User App**: Users can only see their own data and public alerts
- **Admin App**: Admins can view all user reports and alerts (no PII access)
- **Super Admin App**: Full system access and management

### App Identification
Each app identified using:
```javascript
// Custom claims in JWT
{
  "app_type": "user", // "user", "admin", "super_admin"
  "user_role": "admin",
  "permissions": ["read_reports", "manage_alerts"]
}
```

### Secure Admin Creation
1. Super admin logs into web interface
2. Fills admin creation form with required details
3. System generates secure credentials
4. Encrypted sharing mechanism for credentials
5. Admin can login with provided credentials only

## Benefits of This Architecture

✅ **Scalable** - Easy to add new user types and features  
✅ **Secure** - Role-based database security  
✅ **Maintainable** - Single codebase, shared database  
✅ **User-Friendly** - Appropriate UI for each user type  
✅ **Future-Proof** - Easy to extend with new app types  

## Next Steps

1. **Phase 1**: Set up Supabase backend with RLS
2. **Phase 2**: Update user app for hybrid registration  
3. **Phase 3**: Build super admin web interface
4. **Phase 4**: Develop admin and super admin apps

This architecture leverages your existing foundation perfectly and creates a robust, secure multi-app system for your 3:11 Security platform.