# How to Check if Storage Buckets Exist

There are 3 ways to verify if your Supabase storage buckets are already created:

---

## 🎯 METHOD 1: Supabase Dashboard (Easiest)

### Steps:

1. **Go to:** https://supabase.com/dashboard
2. **Login** with your credentials
3. **Select** your project: `311_security_user_app`
4. **Click** "Storage" in the left sidebar
5. **Look for these 3 buckets:**
   - `avatars`
   - `crime-evidence`
   - `notification-images`

### What you'll see:

**If buckets exist:**
```
Storage
├── avatars ✅
├── crime-evidence ✅
└── notification-images ✅
```

**If buckets are missing:**
```
Storage
└── (empty or other buckets)
```

---

## 🎯 METHOD 2: SQL Query (Most Accurate)

### Steps:

1. **Go to:** Supabase Dashboard → SQL Editor
2. **Copy** the contents of `supabase/migrations/check_storage_buckets.sql`
3. **Paste** into SQL Editor
4. **Click** "Run" (or press Ctrl+Enter)

### What you'll see:

**Example output if all buckets exist:**
```
| id                    | name                  | status      |
|-----------------------|----------------------|-------------|
| avatars               | avatars              | ✅ REQUIRED |
| crime-evidence        | crime-evidence       | ✅ REQUIRED |
| notification-images   | notification-images  | ✅ REQUIRED |
```

**Example output if buckets are missing:**
```
| bucket_name           | status      |
|-----------------------|-------------|
| avatars               | ❌ MISSING  |
| crime-evidence        | ❌ MISSING  |
| notification-images   | ❌ MISSING  |
```

The SQL script will show you:
- ✅ Which buckets exist
- ❌ Which buckets are missing
- 📊 Storage usage statistics
- 🔒 Configured policies
- 📈 Summary report

---

## 🎯 METHOD 3: Dart Script (For Developers)

### Steps:

1. **Open terminal** in your project directory
2. **Run:**
   ```bash
   dart run check_buckets.dart
   ```

### What you'll see:

**If all buckets exist:**
```
============================================
CHECKING SUPABASE STORAGE BUCKETS
============================================

✅ Connected to Supabase

Checking for required buckets...

✅ avatars - EXISTS
   Files: 5

✅ crime-evidence - EXISTS
   Files: 12

✅ notification-images - EXISTS
   Files: 3

============================================
SUMMARY
============================================
Total required: 3
Existing: 3
Missing: 0

✅ ALL BUCKETS CONFIGURED!

Your storage is ready to use! 🎉
============================================
```

**If buckets are missing:**
```
============================================
CHECKING SUPABASE STORAGE BUCKETS
============================================

✅ Connected to Supabase

Checking for required buckets...

❌ avatars - MISSING
   Error: Bucket not found

❌ crime-evidence - MISSING
   Error: Bucket not found

❌ notification-images - MISSING
   Error: Bucket not found

============================================
SUMMARY
============================================
Total required: 3
Existing: 0
Missing: 3

⚠️ SOME BUCKETS ARE MISSING

Next steps:
1. Go to https://supabase.com/dashboard
2. Select your project
3. Go to Storage
4. Create the missing buckets
============================================
```

---

## 🚀 Quick Check Script

If you want to just run a quick check, use this terminal command:

```powershell
cd "C:\Users\yamme\OneDrive\Desktop\new development\311_security_user_app\311_security_user_app"
dart run check_buckets.dart
```

---

## ✅ What to Do Based on Results

### If ALL 3 buckets exist:
✅ **You're all set!** No action needed.
- Your app should work fine
- Profile pictures will upload
- Evidence photos will upload
- Notifications with images will work

### If SOME buckets are missing:
⚠️ **Create the missing ones:**
1. Go to Supabase Dashboard → Storage
2. Click "New Bucket"
3. Create each missing bucket with these settings:
   - **avatars:** Public, 5MB limit
   - **crime-evidence:** Public, 10MB limit
   - **notification-images:** Public, 5MB limit

### If NO buckets exist:
❌ **Run the setup script:**
- Copy `supabase/migrations/create_storage_buckets.sql`
- Paste into Supabase SQL Editor
- Click "Run"
- All 3 buckets will be created automatically!

---

## 🐛 Troubleshooting

### "Connection error" when running Dart script
**Solution:**
- Check your `.env` file has `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- Verify your internet connection
- Try Method 1 (Dashboard) instead

### "Permission denied" in SQL query
**Solution:**
- Make sure you're logged in as the project owner
- Check your Supabase user role
- Try Method 1 (Dashboard) instead

### Can't find Storage section in dashboard
**Solution:**
- Make sure you selected the correct project
- Storage should be in the left sidebar (folder icon)
- If missing, your project may need Storage enabled

---

## 📊 Recommended: Use Method 1 (Dashboard)

**Why?**
- ✅ Most visual
- ✅ No SQL knowledge needed
- ✅ Can see file contents
- ✅ Can create buckets immediately
- ✅ Works on any device

Just login and look! Takes 10 seconds. 👀

---

**Quick Answer:** Go to https://supabase.com/dashboard → Storage and see if you have 3 buckets! 🚀

