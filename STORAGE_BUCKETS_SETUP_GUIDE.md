# Storage Buckets Setup Guide
## 3:11 Security User App

**Date:** November 17, 2025  
**Purpose:** Create required Supabase storage buckets

---

## 📦 Required Buckets

Your app needs 3 storage buckets:

1. **`avatars`** - User profile pictures (5MB limit)
2. **`crime-evidence`** - Crime report evidence photos (10MB limit)
3. **`notification-images`** - Notification attachments (5MB limit)

---

## 🎯 METHOD 1: Using Supabase Dashboard (Easiest)

### Step-by-Step:

#### 1. Login to Supabase
Go to: https://supabase.com/dashboard

#### 2. Select Your Project
Click on your `311_security_user_app` project

#### 3. Navigate to Storage
Left sidebar → **Storage** (icon looks like a folder)

#### 4. Create Avatars Bucket

**Click "New Bucket"**

```
Bucket Name: avatars
Public bucket: ✅ ON
File size limit: 5 MB
Allowed MIME types: image/jpeg, image/jpg, image/png, image/webp
```

**Click "Create Bucket"**

#### 5. Create Crime-Evidence Bucket

**Click "New Bucket"**

```
Bucket Name: crime-evidence
Public bucket: ✅ ON
File size limit: 10 MB
Allowed MIME types: image/jpeg, image/jpg, image/png, image/webp
```

**Click "Create Bucket"**

#### 6. Create Notification-Images Bucket

**Click "New Bucket"**

```
Bucket Name: notification-images
Public bucket: ✅ ON
File size limit: 5 MB
Allowed MIME types: image/jpeg, image/jpg, image/png, image/webp
```

**Click "Create Bucket"**

#### 7. Configure Policies (Important!)

For each bucket, click the **bucket name** → **Policies** tab

**For avatars bucket:**
- Click "New Policy"
- Select "Allow authenticated users to upload"
- Apply to: `profiles` folder
- Save

**For crime-evidence bucket:**
- Click "New Policy"
- Select "Allow authenticated users to upload"
- Apply to: `evidence` folder
- Save

**For notification-images bucket:**
- Click "New Policy"
- Select "Allow admin users to upload"
- Save

---

## 🎯 METHOD 2: Using SQL Editor (Advanced)

### Step-by-Step:

#### 1. Open SQL Editor
Supabase Dashboard → **SQL Editor** (left sidebar)

#### 2. Run Migration Script
Copy the contents of `supabase/migrations/create_storage_buckets.sql` and paste into the SQL editor

#### 3. Execute
Click **"Run"** button (or Ctrl+Enter)

#### 4. Verify
You should see:
```
Success! 3 rows affected.
```

#### 5. Check Storage
Go to Storage section and verify all 3 buckets appear

---

## 🎯 METHOD 3: Using Supabase CLI (For Developers)

### Step-by-Step:

#### 1. Ensure CLI is installed
```bash
npm install -g supabase
```

#### 2. Login to Supabase
```bash
supabase login
```

#### 3. Link your project
```bash
cd "C:\Users\yamme\OneDrive\Desktop\new development\311_security_user_app\311_security_user_app"
supabase link --project-ref YOUR_PROJECT_REF
```

#### 4. Run migration
```bash
supabase db push
```

This will apply all migrations including the storage buckets.

---

## ✅ Verification

### Check if buckets exist:

#### Via Dashboard:
1. Go to Storage
2. You should see 3 buckets:
   - avatars
   - crime-evidence
   - notification-images

#### Via SQL:
Run this query in SQL Editor:
```sql
SELECT id, name, public, file_size_limit, created_at
FROM storage.buckets
WHERE id IN ('avatars', 'crime-evidence', 'notification-images');
```

Should return 3 rows.

#### Via App:
1. Run your Flutter app
2. If buckets are missing, app will show error on startup:
   ```
   Storage configuration error: Bucket "avatars" is not available.
   ```
3. If no error, buckets are configured correctly! ✅

---

## 🔒 Bucket Policies Summary

### Avatars Bucket:
- ✅ **Public Read** - Anyone can view profile pictures
- ✅ **Authenticated Upload** - Logged-in users can upload their own avatar
- ✅ **Authenticated Update** - Users can update their own avatar
- ✅ **Authenticated Delete** - Users can delete their own avatar

### Crime-Evidence Bucket:
- ✅ **Authenticated Read** - Logged-in users can view evidence
- ✅ **Authenticated Upload** - Logged-in users can upload evidence
- ✅ **Admin Full Access** - Admins can view/delete all evidence

### Notification-Images Bucket:
- ✅ **Public Read** - Anyone can view notification images
- ✅ **Admin Only Upload** - Only admins can upload notification images
- ✅ **Admin Update/Delete** - Admins can manage all images

---

## 📁 Folder Structure

Your buckets will organize files as follows:

### Avatars:
```
avatars/
  └── profiles/
      ├── profile_user1_1234567890.jpg
      ├── profile_user2_1234567891.jpg
      └── ...
```

### Crime-Evidence:
```
crime-evidence/
  └── evidence/
      ├── evidence_user1_1234567890.jpg
      ├── evidence_user1_1234567891.jpg
      └── ...
```

### Notification-Images:
```
notification-images/
  ├── crime-alerts/
  │   └── alert_1234567890.jpg
  ├── safety-alerts/
  │   └── safety_1234567890.jpg
  └── emergency/
      └── emergency_1234567890.jpg
```

---

## 🧪 Testing Upload

### Test Avatar Upload:

#### 1. Run your app
```bash
flutter run -d chrome
```

#### 2. Sign in and go to Profile

#### 3. Click on profile picture and select an image

#### 4. Check Supabase Storage
- Go to Storage → avatars → profiles
- You should see your uploaded image!

### Test Evidence Upload:

#### 1. Go to "Report Crime"

#### 2. Attach photos

#### 3. Submit report

#### 4. Check Supabase Storage
- Go to Storage → crime-evidence → evidence
- You should see the evidence photos!

---

## 🐛 Troubleshooting

### Issue: "Bucket not found" error

**Solution:**
1. Check bucket name spelling (case-sensitive!)
2. Verify bucket exists in Supabase Dashboard → Storage
3. Run verification SQL query

### Issue: "Policy violation" error

**Solution:**
1. Go to Storage → [bucket] → Policies
2. Ensure you have upload/select policies
3. Run the policy creation SQL from the migration script

### Issue: "File too large" error

**Solution:**
1. Check bucket file size limit
2. Avatars: 5MB limit
3. Evidence: 10MB limit
4. App automatically compresses images before upload

### Issue: "Invalid MIME type" error

**Solution:**
1. Ensure only uploading: jpg, jpeg, png, or webp
2. Check bucket allowed MIME types setting
3. App automatically converts to JPEG

---

## 📊 Storage Usage Monitoring

### Check storage usage:
```sql
SELECT 
  bucket_id,
  COUNT(*) as file_count,
  SUM(metadata->>'size')::bigint as total_bytes,
  pg_size_pretty(SUM(metadata->>'size')::bigint) as total_size
FROM storage.objects
WHERE bucket_id IN ('avatars', 'crime-evidence', 'notification-images')
GROUP BY bucket_id;
```

### Set up alerts (recommended):
- Alert when storage > 80% of limit
- Alert when individual file > size limit
- Monitor upload failure rate

---

## 💰 Cost Considerations

### Supabase Storage Pricing:
- **Free Tier:** 1 GB storage, 2 GB bandwidth
- **Pro Tier:** 100 GB storage, 200 GB bandwidth
- **Additional:** $0.021/GB storage, $0.09/GB bandwidth

### Estimated Usage:
- **Avatar:** ~100-200 KB per user (after compression)
- **Evidence:** ~500 KB - 1 MB per photo
- **Notification Images:** ~200-500 KB per image

### For 1,000 users:
- 1,000 avatars × 150 KB = 150 MB
- 5,000 evidence photos × 750 KB = 3.75 GB
- 100 notification images × 350 KB = 35 MB
- **Total:** ~4 GB

**Recommendation:** Pro tier if you expect >1,000 active users

---

## 🔐 Security Best Practices

### 1. Bucket Permissions:
✅ **DO:**
- Keep avatars and notification-images public (read-only)
- Require authentication for uploads
- Limit evidence access to authenticated users

❌ **DON'T:**
- Allow anonymous uploads (spam risk)
- Make evidence bucket fully public (privacy concern)
- Allow users to delete others' files

### 2. File Validation:
✅ **Already Implemented:**
- App validates file size before upload
- App compresses images automatically
- App restricts MIME types to images only

### 3. Rate Limiting:
- Consider adding upload rate limits
- Supabase provides basic rate limiting
- Monitor for abuse patterns

---

## ✅ Completion Checklist

Before marking this as complete:

- [ ] All 3 buckets created in Supabase
- [ ] Buckets are marked as public
- [ ] File size limits configured (5MB, 10MB, 5MB)
- [ ] MIME types restricted to images
- [ ] Policies created for each bucket
- [ ] Tested avatar upload
- [ ] Tested evidence upload
- [ ] App launches without storage errors
- [ ] Verified files appear in Supabase Storage

---

## 🎉 Done!

Once all 3 buckets are created and verified, your app's storage system is ready!

**Next:** Test the app and monitor storage usage in Supabase Dashboard.

---

## 📞 Support

If you encounter issues:
1. Check Supabase Status: https://status.supabase.com
2. Review Supabase Storage Docs: https://supabase.com/docs/guides/storage
3. Check app logs for specific error messages
4. Verify policies with the verification SQL query

---

**Great job setting up your storage! Your app can now handle file uploads! 📸✨**

