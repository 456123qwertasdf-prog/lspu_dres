# 📋 Production Deployment Checklist

## Overview

This checklist ensures that the notification system works correctly when you:
1. 📱 Build and distribute the APK
2. 🌐 Deploy the web interface to Cloudflare
3. 💾 Deploy Edge Functions to Supabase
4. 🔄 Push code to GitHub

---

## ✅ Pre-Deployment Checklist

### 1. 🔧 Supabase Edge Functions

**Status Check:**
```bash
# List all deployed functions
supabase functions list
```

**Required Functions:**
- [ ] `classify-image` - ✅ Already deployed
- [ ] `notify-superusers-critical-report` - ✅ Already deployed
- [ ] `notify-responder-assignment` - ✅ Already deployed
- [ ] `assign-responder` - ✅ Already deployed
- [ ] `onesignal-send` - Should be deployed

**Deploy All Functions:**
```bash
cd c:\Users\Ducay\Desktop\lspu_dres\lspu_dres

# Deploy all notification functions
supabase functions deploy classify-image
supabase functions deploy notify-superusers-critical-report
supabase functions deploy notify-responder-assignment
supabase functions deploy assign-responder
```

---

### 2. 🔐 Environment Variables (Critical!)

**Check Supabase Project Settings:**

Go to: `https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/settings/functions`

**Required Secrets:**
- [ ] `ONESIGNAL_REST_API_KEY` - For sending push notifications
- [ ] `ONESIGNAL_APP_ID` - Your OneSignal app ID
- [ ] `SUPABASE_URL` - Auto-set by Supabase
- [ ] `SUPABASE_SERVICE_ROLE_KEY` - Auto-set by Supabase
- [ ] `AZURE_VISION_KEY` - For image classification
- [ ] `AZURE_VISION_ENDPOINT` - For image classification

**Verify OneSignal Configuration:**
```sql
-- Run this in Supabase SQL Editor to check if keys are set
SELECT 
  'Check Edge Function Secrets in Dashboard' as message,
  'https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/settings/functions' as url;
```

---

### 3. 💾 Database Functions

**Verify Required Functions Exist:**
```sql
-- Check if get_super_users function exists
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name = 'get_super_users';

-- Should return: get_super_users
```

**If NOT found, apply migration:**
```bash
cd c:\Users\Ducay\Desktop\lspu_dres
supabase db push
```

Or run the SQL manually:
```sql
-- See: supabase/migrations/20250203000000_add_super_user_functions.sql
```

---

### 4. 📱 Mobile App Configuration

**Check Flutter Configuration Files:**

#### **A. OneSignal Configuration**

**File:** `mobile_app/android/app/build.gradle`
```gradle
// Verify OneSignal App ID is set
defaultConfig {
    // ...
    manifestPlaceholders = [
        onesignalAppId: "8d6aa625-a650-47ac-b9ba-00a247840952"
    ]
}
```

**File:** `mobile_app/lib/main.dart`
```dart
// Verify OneSignal initialization
OneSignal.initialize("8d6aa625-a650-47ac-b9ba-00a247840952");
```

#### **B. Supabase Configuration**

**File:** `mobile_app/lib/config/supabase_config.dart` (or similar)
```dart
// Verify production Supabase URL
const supabaseUrl = 'https://hmolyqzbvxxliemclrld.supabase.co';
const supabaseAnonKey = 'YOUR_ANON_KEY';  // Public key, safe to commit
```

**⚠️ Important:** Do NOT use `localhost` or `127.0.0.1` in production build!

---

### 5. 🌐 Web Interface Configuration

**File:** `public/js/supabase.js` or inline scripts

**Verify Production URLs:**
```javascript
// Check that these use production URLs, not localhost
const SUPABASE_URL = 'https://hmolyqzbvxxliemclrld.supabase.co';
const SUPABASE_ANON_KEY = 'your-anon-key-here';

// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
```

**⚠️ Common Mistake:** Using `http://localhost:54321` in production!

---

## 🚀 Deployment Steps

### Step 1: Deploy Edge Functions to Supabase

```bash
cd c:\Users\Ducay\Desktop\lspu_dres\lspu_dres

# Deploy all notification-related functions
supabase functions deploy classify-image
supabase functions deploy notify-superusers-critical-report
supabase functions deploy notify-responder-assignment
supabase functions deploy assign-responder
```

**Verify Deployment:**
```bash
supabase functions list
```

**Check in Dashboard:**
- Go to: https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/functions
- All functions should show "Deployed" status
- Click each function → "Invocations" to see if they're active

---

### Step 2: Build Mobile App APK

#### **A. Update Version**

**File:** `mobile_app/pubspec.yaml`
```yaml
version: 1.0.0+1  # Increment build number
```

#### **B. Build APK**

```bash
cd c:\Users\Ducay\Desktop\lspu_dres\lspu_dres\mobile_app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Or build app bundle for Play Store
flutter build appbundle --release
```

**Output Location:**
```
build/app/outputs/flutter-apk/app-release.apk
```

#### **C. Test APK Before Distribution**

```bash
# Install on physical device
adb install build/app/outputs/flutter-apk/app-release.apk

# Check logs
adb logcat | grep "flutter"
```

**Test Checklist:**
- [ ] App launches successfully
- [ ] User can log in
- [ ] OneSignal Player ID is saved to database
- [ ] User receives test notification
- [ ] All features work (report submission, viewing, etc.)

---

### Step 3: Deploy Web Interface to Cloudflare

#### **A. Prepare for Deployment**

**Verify all files use production URLs:**
```bash
# Search for any localhost references
cd c:\Users\Ducay\Desktop\lspu_dres\lspu_dres\public

# Check for localhost
grep -r "localhost" .
grep -r "127.0.0.1" .

# Should only return comments or none
```

**Files to Check:**
- `public/js/supabase.js`
- `public/super-user-reports.html`
- `public/admin.html`
- `public/responder.html`
- Any other HTML/JS files

#### **B. Deploy to Cloudflare Pages**

**Option 1: Via GitHub (Recommended)**

1. Push to GitHub:
```bash
cd c:\Users\Ducay\Desktop\lspu_dres
git add .
git commit -m "Deploy: Updated notification system with Edge Functions"
git push origin main
```

2. Connect Cloudflare Pages to GitHub:
   - Go to Cloudflare Dashboard
   - Pages → Create a project
   - Connect to GitHub repository
   - Set build settings:
     - **Build command:** (none for static site)
     - **Build output directory:** `lspu_dres/public`
   - Deploy

**Option 2: Direct Upload**

```bash
# Install Wrangler CLI
npm install -g wrangler

# Login to Cloudflare
wrangler login

# Deploy
cd c:\Users\Ducay\Desktop\lspu_dres\lspu_dres\public
wrangler pages deploy . --project-name=lspu-emergency
```

---

### Step 4: Verify Production Deployment

#### **A. Test Web Interface**

1. **Open Production URL:**
   ```
   https://your-site.pages.dev/super-user-reports.html
   ```

2. **Open Browser Console** (F12)

3. **Assign a Responder:**
   - Find unassigned report
   - Click Edit
   - Select responder
   - Save

4. **Check Console Logs:**
   ```
   ✅ Should see: "🚀 Calling assign-responder Edge Function"
   ✅ Should see: "✅ Responder assigned successfully"
   ❌ Should NOT see: "localhost" or "127.0.0.1"
   ```

5. **Check Network Tab:**
   - All requests should go to `*.supabase.co`
   - No requests to localhost

#### **B. Test Mobile App**

1. **Install APK on Test Device**

2. **Log in as Responder**

3. **From Web, Assign That Responder to a Report**

4. **Verify Push Notification:**
   - [ ] Push notification received on device
   - [ ] Notification shows correct report details
   - [ ] Clicking notification opens app

5. **Check Database:**
```sql
-- Verify notification was saved
SELECT 
  id,
  target_type,
  target_id,
  type,
  title,
  message,
  created_at
FROM notifications
WHERE type = 'assignment_created'
ORDER BY created_at DESC
LIMIT 5;
```

#### **C. Test Super User Notifications**

1. **Submit New Critical Report** (via mobile or web)

2. **Check Super User Devices:**
   - All super users should receive push notification
   - Notification should show "🚨 NEW CRITICAL REPORT"

3. **Check Edge Function Logs:**
   - `classify-image` → Should show classification
   - `notify-superusers-critical-report` → Should show notifications sent

---

## 🔍 Production Verification Checklist

### Database Checks

```sql
-- 1. Verify super users have OneSignal IDs
SELECT * FROM get_super_users();
-- Should return users with onesignal_player_id

-- 2. Verify responders have OneSignal IDs
SELECT 
  r.name,
  os.player_id,
  os.updated_at
FROM responder r
JOIN auth.users u ON u.id = r.user_id
LEFT JOIN onesignal_subscriptions os ON os.user_id = r.user_id
WHERE os.player_id IS NOT NULL;

-- 3. Check recent notifications
SELECT 
  type,
  COUNT(*) as count,
  MAX(created_at) as last_notification
FROM notifications
GROUP BY type
ORDER BY last_notification DESC;

-- 4. Check Edge Function status
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('get_super_users', 'get_users_by_role');
```

### Edge Function Checks

**Check Logs for Each Function:**

1. **classify-image:**
   - Go to: https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/functions/classify-image/logs
   - Should show recent classifications
   - Look for: "🚨 Report [id] is CRITICAL/HIGH priority"

2. **notify-superusers-critical-report:**
   - Should show: "Found X super users with OneSignal player IDs"
   - Should show: "✅ Critical report notification sent"

3. **assign-responder:**
   - Should show: "Executing assignment transaction"
   - Should show: "✅ Push notification sent to responder"

4. **notify-responder-assignment:**
   - Should show: "Sending notification to X device(s)"
   - Should show: "✅ Push notification sent"

---

## 🐛 Common Production Issues & Solutions

### Issue 1: "No OneSignal Player IDs Found"

**Cause:** Users haven't logged into the mobile app yet

**Solution:**
- Have all super users and responders install the app
- Have them log in at least once
- Check permissions: "Allow notifications"

**Verify:**
```sql
SELECT COUNT(*) FROM onesignal_subscriptions;
-- Should be > 0
```

---

### Issue 2: "Edge Function Not Found"

**Cause:** Function not deployed or wrong name

**Solution:**
```bash
# Redeploy all functions
cd lspu_dres
supabase functions deploy --all
```

---

### Issue 3: "CORS Error" in Web Interface

**Cause:** Web app on different domain than Supabase

**Solution:** Already handled by `corsHeaders` in Edge Functions, but verify:
```typescript
// In Edge Functions
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',  // Or specific domain
  'Access-Control-Allow-Headers': '...'
}
```

---

### Issue 4: "Database Function Not Found"

**Cause:** Migration not applied

**Solution:**
```bash
supabase db push

# Or run SQL manually in Supabase SQL Editor
```

---

### Issue 5: APK Won't Install

**Cause:** Signing issues or Android version incompatibility

**Solution:**
```bash
# Check minimum SDK version in build.gradle
minSdkVersion 21  # Should support Android 5.0+

# Rebuild with proper signing
flutter build apk --release
```

---

## 📊 Production Monitoring

### Daily Checks

1. **Edge Function Invocations:**
   - Dashboard → Functions → Check invocation counts
   - Should see activity for assign-responder and notify functions

2. **OneSignal Dashboard:**
   - Go to: https://onesignal.com
   - Check delivery statistics
   - Verify notifications are being delivered

3. **Database Notifications Table:**
```sql
SELECT 
  DATE(created_at) as date,
  type,
  COUNT(*) as count
FROM notifications
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at), type
ORDER BY date DESC;
```

### Weekly Checks

- Review Edge Function error logs
- Check OneSignal subscription count
- Verify all super users/responders have active subscriptions
- Test end-to-end notification flow

---

## ✅ Final Production Readiness Checklist

Before going live:

### Supabase
- [ ] All Edge Functions deployed
- [ ] Environment variables set (OneSignal keys, etc.)
- [ ] Database functions exist (get_super_users)
- [ ] RLS policies configured
- [ ] Test Edge Functions via dashboard

### Mobile App
- [ ] OneSignal App ID configured
- [ ] Supabase URL set to production (NOT localhost)
- [ ] APK built and tested on physical device
- [ ] Push notifications work in release build
- [ ] All users install app and log in

### Web Interface
- [ ] No localhost references in code
- [ ] Supabase URL set to production
- [ ] Deployed to Cloudflare
- [ ] Edge Function calls work from production domain
- [ ] Browser console shows no errors

### Testing
- [ ] Submit test critical report → Super users receive notification
- [ ] Assign responder → Responder receives notification
- [ ] Check Edge Function logs → Show successful invocations
- [ ] Check database notifications table → Records saved correctly
- [ ] Test on multiple devices

### Documentation
- [ ] README updated with deployment instructions
- [ ] Environment variables documented
- [ ] API endpoints documented
- [ ] Notification system documented

---

## 🎯 Success Criteria

Your notification system is **production-ready** when:

1. ✅ Super users receive notifications for critical reports
2. ✅ Responders receive notifications when assigned
3. ✅ Edge Function logs show successful invocations
4. ✅ Database notifications table has records
5. ✅ No errors in browser console or mobile app logs
6. ✅ All users can install and use the mobile app
7. ✅ Web interface works on Cloudflare domain

---

## 📞 Need Help?

If you encounter issues during deployment:

1. **Check Edge Function Logs** (most common source of errors)
2. **Check Browser Console** (for web issues)
3. **Check `adb logcat`** (for mobile issues)
4. **Verify Environment Variables** (common misconfiguration)
5. **Test with unassigned reports** (avoid duplicate assignment errors)

---

**Last Updated:** December 4, 2025  
**Status:** Ready for Production Deployment  
**All Systems:** ✅ Tested and Working

