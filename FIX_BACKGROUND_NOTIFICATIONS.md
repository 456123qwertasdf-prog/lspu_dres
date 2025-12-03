# Fix Background Notifications for Closed App

## 🔍 Problem
When the mobile app is **closed** (but user is still logged in), push notifications are not being received.

## ✅ Solution Steps

### Step 1: Verify OneSignal Player ID is Saved

1. **Run the diagnostic query:**
   - Open Supabase SQL Editor
   - Run `DIAGNOSE_CITIZEN_NOTIFICATIONS.sql`
   - Check if citizendemo has a `player_id`

2. **If NO player_id found:**
   ```
   ❌ The app has not registered with OneSignal yet
   ```
   
   **Fix:** Open the mobile app while logged in as citizendemo:
   - Open the app
   - Wait 10 seconds (let OneSignal initialize)
   - Look for this log in the app console:
     ```
     ✅ OneSignal Player ID saved to Supabase: <player_id>
     ```
   - Run the diagnostic query again to confirm

---

### Step 2: Check OneSignal Environment Variables in Supabase

The edge functions need OneSignal API credentials to send notifications.

1. **Go to Supabase Dashboard:**
   - Project Settings → Edge Functions
   - Look for "Environment Variables" or "Secrets"

2. **Check these secrets exist:**
   ```
   ONESIGNAL_APP_ID=8d6aa625-a650-47ac-b9ba-00a247840952
   ONESIGNAL_REST_API_KEY=<your-rest-api-key>
   ```

3. **Get your REST API Key:**
   - Go to https://app.onesignal.com/
   - Select your app
   - Settings → Keys & IDs
   - Copy "REST API Key" (NOT "User Auth Key")

4. **Set the secrets in Supabase:**
   
   **Option A: Using Supabase CLI**
   ```bash
   supabase secrets set ONESIGNAL_APP_ID=8d6aa625-a650-47ac-b9ba-00a247840952
   supabase secrets set ONESIGNAL_REST_API_KEY=your_actual_rest_api_key_here
   ```

   **Option B: Using Supabase Dashboard**
   - Go to Project Settings → Edge Functions
   - Add each secret manually in the UI

---

### Step 3: Test Background Notifications

1. **On the mobile device (citizendemo account):**
   - Open the app
   - Verify you're logged in as citizendemo
   - Press the Home button (don't log out, don't force close)
   - Lock the screen

2. **On the web app (super_user account):**
   - Login as super_user
   - Create an announcement/alert:
     - Type: Emergency or General
     - Target Audience: "All" or "Citizens"
     - Title: "Test Notification"
     - Message: "Testing background notifications"
   - Click Send/Publish

3. **Expected Result:**
   - Mobile device should receive a push notification
   - Notification should show even though app is closed
   - Tapping notification should open the app

---

### Step 4: Check Edge Function Logs

If notifications still don't work, check the logs:

1. **View announcement-notify logs:**
   ```bash
   supabase functions logs announcement-notify --limit 20
   ```

2. **View onesignal-send logs:**
   ```bash
   supabase functions logs onesignal-send --limit 20
   ```

3. **Look for these messages:**
   
   **✅ Good:**
   ```
   Found X OneSignal subscriptions for Y target users
   OneSignal notifications sent to X devices
   OneSignal API response: { recipients: X }
   ```

   **❌ Problems:**
   ```
   No OneSignal player IDs found
   ➡️ User needs to open the app to register

   ONESIGNAL_REST_API_KEY not configured
   ➡️ Set the API key in Supabase secrets

   OneSignal API error: 400
   ➡️ Wrong API key format, check you're using REST API Key

   OneSignal API error: 401
   ➡️ Invalid API key, get correct key from OneSignal dashboard
   ```

---

### Step 5: Android Background Restrictions

Some Android devices aggressively kill apps in the background. Check device settings:

1. **Disable Battery Optimization:**
   - Go to Settings → Apps → Your App
   - Battery → Optimize battery usage → Don't optimize
   - OR: Battery → Battery optimization → Not optimized

2. **Allow Background Activity:**
   - Settings → Apps → Your App
   - Mobile data & Wi-Fi → Allow background data usage

3. **Disable Adaptive Battery (if available):**
   - Settings → Battery → Adaptive Battery → Turn OFF
   - (This feature kills apps more aggressively)

4. **For Xiaomi/MIUI devices:**
   - Security → Permissions → Autostart → Enable for your app
   - Recent apps → Lock your app (prevents it from being cleared)

5. **For Huawei devices:**
   - Settings → Apps → Your App → Battery
   - Set to "No restrictions"
   - Protected apps → Enable your app

---

## 🧪 Quick Test Checklist

Before testing, ensure:

- [ ] **citizendemo has OneSignal player_id in database** (run diagnostic query)
- [ ] **ONESIGNAL_REST_API_KEY is set in Supabase** (check secrets)
- [ ] **ONESIGNAL_APP_ID is set in Supabase** (check secrets)
- [ ] **Edge functions deployed** (announcement-notify, onesignal-send)
- [ ] **Mobile app has notification permissions** (Settings → Apps → Permissions)
- [ ] **Battery optimization disabled** for the app

---

## 🔧 Common Issues & Fixes

### Issue 1: "No OneSignal player IDs found"

**Problem:** User hasn't opened the app to register with OneSignal

**Fix:**
1. Open mobile app while logged in
2. Wait 10 seconds for initialization
3. Check logs for "OneSignal Player ID saved"

---

### Issue 2: "OneSignal not configured"

**Problem:** API key not set in Supabase environment variables

**Fix:**
1. Get REST API Key from OneSignal dashboard
2. Set in Supabase: `supabase secrets set ONESIGNAL_REST_API_KEY=your_key`
3. Redeploy edge functions (optional, but recommended)

---

### Issue 3: Notifications work when app is open, but not closed

**Problem:** Android battery optimization killing OneSignal service

**Fix:**
1. Disable battery optimization for the app
2. Allow background data usage
3. For Xiaomi/Huawei: Enable autostart/protected apps

---

### Issue 4: "content_available" not working

**Problem:** The notification payload might not have correct settings

**Current code already includes:**
```typescript
content_available: true, // ✅ This allows background notifications
android_channel_id: '62b67b1a-b2c2-4073-92c5-3b1d416a4720', // ✅ Emergency channel
priority: 10, // ✅ Maximum priority
```

**Verify in OneSignal dashboard:**
1. Go to OneSignal Dashboard → Settings → Platforms
2. Check Android configuration
3. Ensure "Background Data Enabled" is ON

---

## 📱 Testing Procedure

### Test 1: App in Background (Home button pressed)
```
1. Open app → Login as citizendemo → Press Home button
2. Create alert from web as super_user
3. ✅ Should receive notification
```

### Test 2: App Fully Closed (Swiped away)
```
1. Open app → Login as citizendemo → Swipe away from recent apps
2. Create alert from web as super_user
3. ✅ Should receive notification (if OneSignal service is running)
```

### Test 3: Device Locked
```
1. Open app → Login as citizendemo → Lock device
2. Create alert from web as super_user
3. ✅ Should receive notification on lock screen
```

### Test 4: After Device Reboot
```
1. Reboot device (don't open app)
2. Create alert from web as super_user
3. ⚠️ May NOT receive notification (app needs to start once after reboot)
4. Open app once → Close it
5. Create alert again
6. ✅ Should receive notification
```

---

## 🎯 Expected Behavior

### ✅ What SHOULD Work

- Notifications when app is in background (Home button)
- Notifications when app is closed (swiped away)
- Notifications on lock screen
- Notifications with app open
- Notifications with internet connection

### ⚠️ What May NOT Work (Android Limitations)

- Notifications after device reboot (before opening app once)
- Notifications with severe battery optimization
- Notifications with "Force Stop" app
- Notifications with data restrictions enabled
- Notifications with airplane mode ON

---

## 🔍 Debug Commands

### Check OneSignal subscriptions in database:
```sql
SELECT 
  u.email,
  os.player_id,
  os.platform,
  os.updated_at
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
WHERE u.email = 'citizendemo@example.com';
```

### Check recent announcements:
```sql
SELECT id, title, type, target_audience, created_at 
FROM announcements 
ORDER BY created_at DESC 
LIMIT 5;
```

### Check notifications sent to citizendemo:
```sql
SELECT n.type, n.title, n.created_at, n.read
FROM notifications n
JOIN auth.users u ON n.user_id = u.id
WHERE u.email = 'citizendemo@example.com'
ORDER BY n.created_at DESC
LIMIT 10;
```

### View edge function logs:
```bash
# Announcement notifications
supabase functions logs announcement-notify --limit 20

# OneSignal send
supabase functions logs onesignal-send --limit 20
```

---

## 📞 Still Not Working?

If you've completed all steps above and notifications still don't work:

1. **Run the full diagnostic query** (`DIAGNOSE_CITIZEN_NOTIFICATIONS.sql`)
2. **Check Supabase edge function logs** for errors
3. **Check mobile app logs** for OneSignal errors
4. **Test with OneSignal Dashboard** (send test notification directly)
5. **Verify device has internet connection** and notifications enabled
6. **Try on a different device** to rule out device-specific issues

---

## 🎉 Success Criteria

Notifications are working correctly when:

1. ✅ citizendemo has `player_id` in `onesignal_subscriptions` table
2. ✅ Edge function logs show "OneSignal notifications sent to X devices"
3. ✅ Mobile device receives notification when app is closed
4. ✅ Tapping notification opens the app to correct screen
5. ✅ Notification sound plays (emergency sound for urgent alerts)

---

**Last Updated:** December 3, 2025

