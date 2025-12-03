# Fix: OneSignal Player ID Not Saving

## 🐛 The Problem

The mobile app was saving OneSignal player IDs to the **wrong table**:
- ❌ Saving to: `onesignal_subscriptions` table
- ✅ Edge Function expects: `users.onesignal_player_id` column

This is why even after logging into the mobile app, notifications still fail with:
```
WARNING: No OneSignal player ID found for responder Demo Responder
```

## ✅ The Fix

Updated `mobile_app/lib/services/onesignal_service.dart` to save player ID to **both** locations:
1. `users.onesignal_player_id` (required for responder notifications)
2. `onesignal_subscriptions` (for tracking multiple devices)

---

## 🚀 Quick Fix (Without Rebuilding App)

If you want to test notifications **right now** without rebuilding the app:

### Step 1: Get Your OneSignal Player ID

**Option A: From OneSignal Dashboard**
1. Go to: https://dashboard.onesignal.com/apps/8d6aa625-a650-47ac-b9ba-00a247840952/audience
2. Click "All Users"
3. Find your device (it will show as "Subscribed")
4. Copy the **Player ID** (looks like: `f2c1234a-5678-90ab-cdef-1234567890ab`)

**Option B: From Mobile App Logs** (if running in debug mode)
1. Open Android Studio or VS Code
2. Check the debug console/logs
3. Look for: `OneSignal Player ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
4. Copy that ID

### Step 2: Update Database Manually

**Option A: Using Supabase Dashboard SQL Editor**
1. Go to: https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/editor
2. Click "SQL Editor"
3. Run this query:

```sql
-- Replace 'YOUR_PLAYER_ID_HERE' with the actual player ID from Step 1
-- Replace 'responder@lspu-dres.com' with the responder's email

UPDATE users
SET onesignal_player_id = 'YOUR_PLAYER_ID_HERE',
    updated_at = NOW()
WHERE email = 'responder@lspu-dres.com';

-- Verify it was updated
SELECT id, email, onesignal_player_id 
FROM users 
WHERE email = 'responder@lspu-dres.com';
```

**Option B: Find User ID First** (if you don't know the email)
```sql
-- First, find all responders
SELECT u.id, u.email, u.onesignal_player_id, r.name as responder_name
FROM users u
JOIN responder r ON r.user_id = u.id
WHERE r.name = 'Demo Responder';

-- Then update using the user ID
UPDATE users
SET onesignal_player_id = 'YOUR_PLAYER_ID_HERE',
    updated_at = NOW()
WHERE id = 'USER_ID_FROM_ABOVE_QUERY';
```

### Step 3: Test Notifications

1. Go to Super User Reports page
2. Assign Demo Responder to a critical report
3. Check the mobile device - should receive push notification! 🎉

---

## 🔨 Permanent Fix (Rebuild Mobile App)

To apply the code fix permanently:

### Step 1: Rebuild the Mobile App

```bash
cd mobile_app

# Clean old build
flutter clean

# Get dependencies
flutter pub get

# Build and install on device
flutter run
# or for release build:
flutter build apk
flutter install
```

### Step 2: Re-login

1. Open the rebuilt app
2. Log out (if already logged in)
3. Log back in as Demo Responder
4. Grant notification permissions when prompted

### Step 3: Verify

Check the logs - you should see:
```
✅ OneSignal Player ID saved to users table: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
✅ OneSignal Player ID also saved to subscriptions table
```

---

## 📊 How to Verify It's Working

### Check Database:
```sql
SELECT 
    u.email,
    u.onesignal_player_id,
    r.name as responder_name,
    CASE 
        WHEN u.onesignal_player_id IS NOT NULL THEN '✅ Has Player ID'
        ELSE '❌ Missing Player ID'
    END as status
FROM users u
JOIN responder r ON r.user_id = u.id
WHERE r.name = 'Demo Responder';
```

### Check Edge Function Logs:
After assigning a responder, check `notify-responder-assignment` logs.

**Before Fix:**
```
WARNING: No OneSignal player ID found for responder Demo Responder
```

**After Fix:**
```
INFO: Sending OneSignal notification to 1 device(s)
INFO: ✅ Push notification sent successfully
```

---

## 🎯 Summary

**Root Cause:** Mobile app saved player ID to wrong table

**Immediate Solution:** Manually update `users.onesignal_player_id` via SQL

**Permanent Solution:** Rebuild mobile app with fixed code

**Impact:** After fix, responder notifications will work immediately when assigned via web interface

---

*Updated: December 3, 2025*
*File Modified: `mobile_app/lib/services/onesignal_service.dart`*

