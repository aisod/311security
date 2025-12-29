# Admin Access Debug Guide

## Step-by-Step Troubleshooting

### 1. Verify You're Using the Admin App
- Make sure you're running `security_311_admin` (not `311_security_user_app`)
- The URL should show the admin app
- Check the browser tab title - it should say "3:11 Security Admin"

### 2. Check Your Role in Supabase
1. Go to your Supabase Dashboard
2. Navigate to **Table Editor** → **profiles**
3. Find your user record (search by email)
4. Check the **role** column - it MUST be exactly:
   - `admin` (for regular admin)
   - `super_admin` (for super admin)
   - NOT `user` (this won't work)

### 3. Verify the Role Value
The role field must match EXACTLY:
- ✅ `admin` - works
- ✅ `super_admin` - works  
- ❌ `user` - won't work
- ❌ `Admin` - won't work (case sensitive)
- ❌ `ADMIN` - won't work (case sensitive)

### 4. Clear Browser Cache
1. Open Chrome DevTools (F12)
2. Right-click the refresh button
3. Select "Empty Cache and Hard Reload"

### 5. Sign Out and Sign Back In
1. Click "Sign Out" in the admin app
2. Wait 2-3 seconds
3. Sign back in with your credentials
4. The app will check your role automatically

### 6. Check Browser Console for Errors
1. Open Chrome DevTools (F12)
2. Go to the "Console" tab
3. Look for any red error messages
4. Look for log messages starting with "AdminProvider:" or "isUserAdmin:"
5. These will show what role was detected

### 7. Manual Role Refresh
If you changed your role in Supabase:
1. Sign out of the admin app
2. Wait a few seconds
3. Sign back in
4. OR click "Refresh Permissions" button on the access denied screen

### 8. Common Issues

**Issue: "Still seeing user screen"**
- You might be logged into the USER app, not the ADMIN app
- Solution: Close the user app and open the admin app separately

**Issue: "Access Denied" after changing role**
- The role change might not have saved in Supabase
- Solution: Double-check the role field in Supabase, make sure you clicked "Save"

**Issue: "Nothing happens when I click Refresh Permissions"**
- Check browser console for errors
- Try signing out and back in instead

### 9. Verify Database Connection
Make sure your `.env` file in `security_311_admin` has:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

### 10. Check Logs
The app now logs detailed information:
- Look for: "isUserAdmin: Found role in database: ..."
- Look for: "AdminProvider: Permission check complete - admin=..."
- These will tell you exactly what role was detected

## Still Not Working?

1. Open Chrome DevTools (F12)
2. Go to Console tab
3. Copy all the log messages
4. Check what role value is being detected
5. Verify it matches exactly what's in Supabase

