# Notifications Troubleshooting Guide

## ✅ Good News: Code is Already Correct at b792623!

The notification edge functions already have the correct OneSignal API endpoint and proper Deno base64 encoding at commit b792623.

## 🔍 Why Notifications Might Not Be Working

Since the code is correct, the issue is likely one of these:

### 1. OneSignal Environment Variables Not Set ⚠️

**Check Supabase Edge Function Secrets:**

Go to: **Supabase Dashboard → Edge Functions → Settings**

Required environment variables:
```
ONESIGNAL_APP_ID=8d6aa625-a650-47ac-b9ba-00a247840952
ONESIGNAL_REST_API_KEY=<your-onesignal-rest-api-key>
```

**How to get the REST API Key:**
1. Go to OneSignal Dashboard: https://app.onesignal.com/
2. Select your app
3. Go to Settings → Keys & IDs
4. Copy the "REST API Key"

**How to set in Supabase:**
```bash
# Using Supabase CLI
supabase secrets set ONESIGNAL_APP_ID=8d6aa625-a650-47ac-b9ba-00a247840952
supabase secrets set ONESIGNAL_REST_API_KEY=your_actual_key_here
```

OR in Supabase Dashboard:
- Go to Project Settings → Edge Functions
- Add secrets under "Environment Variables"

---

### 2. No Player IDs in Database ⚠️

**Check if users have OneSignal Player IDs saved:**

Run this SQL in Supabase SQL Editor:

```sql
-- Check onesignal_subscriptions table
SELECT 
  user_id,
  player_id,
  updated_at
FROM onesignal_subscriptions
ORDER BY updated_at DESC;
```

**Expected:** Should return rows with player_ids

**If empty:**
- Users need to open the mobile app while logged in
- The app will automatically save their OneSignal player ID
- Check mobile app logs to ensure OneSignal initializes properly

---

### 3. Edge Functions Not Deployed ⚠️

**Check if notification functions are deployed to Supabase:**

```bash
# List all deployed functions
supabase functions list

# Should show:
# - notify-responder-assignment
# - notify-superusers-critical-report
# - onesignal-send
# - announcement-notify
```

**If missing, deploy them:**

```bash
# Deploy all notification functions
supabase functions deploy notify-responder-assignment
supabase functions deploy notify-superusers-critical-report
supabase functions deploy onesignal-send
supabase functions deploy announcement-notify
```

---

### 4. Database RPC Function Missing ⚠️

**Check if `get_super_users` function exists:**

Run this SQL:

```sql
-- Check for get_super_users function
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'get_super_users';
```

**If missing, create it:**

```sql
CREATE OR REPLACE FUNCTION public.get_super_users()
RETURNS TABLE (
  id uuid,
  email text,
  role text,
  onesignal_player_id text
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT 
    os.user_id as id,
    u.email,
    u.raw_user_meta_data->>'role' as role,
    os.player_id as onesignal_player_id
  FROM onesignal_subscriptions os
  JOIN auth.users u ON os.user_id = u.id
  WHERE u.raw_user_meta_data->>'role' IN ('super_user', 'admin')
  ORDER BY os.updated_at DESC;
$$;
```

---

## 📱 Testing Notifications

### Test 1: Assignment Notification

1. Login as admin/super_user in web app
2. Create a report (or use existing)
3. Assign it to a responder who has the mobile app open
4. **Expected:** Responder receives push notification

**Check logs:**
```bash
# View edge function logs
supabase functions logs notify-responder-assignment
```

Look for:
- ✅ "Found OneSignal player ID for [responder name]"
- ✅ "OneSignal response: { recipients: 1 }"

---

### Test 2: Critical Report Notification

1. Login as citizen in mobile app
2. Submit a high priority/critical report
3. **Expected:** Super users receive push notification

**Check logs:**
```bash
supabase functions logs notify-superusers-critical-report
```

Look for:
- ✅ "Found X super users with OneSignal player IDs"
- ✅ "OneSignal response: { recipients: X }"

---

### Test 3: Announcement Notification

1. Login as admin in web app
2. Create an announcement
3. Select target audience (all/responders/citizens)
4. **Expected:** Target users receive push notification

**Check logs:**
```bash
supabase functions logs onesignal-send
```

---

## 🔧 Quick Diagnostic Queries

Run these in Supabase SQL Editor:

```sql
-- 1. Check how many users have OneSignal subscriptions
SELECT COUNT(*) as total_subscriptions FROM onesignal_subscriptions;

-- 2. Check OneSignal subscriptions by role
SELECT 
  u.raw_user_meta_data->>'role' as role,
  COUNT(*) as count
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
GROUP BY u.raw_user_meta_data->>'role';

-- 3. Check super users with OneSignal
SELECT 
  u.email,
  u.raw_user_meta_data->>'role' as role,
  os.player_id,
  os.updated_at
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
WHERE u.raw_user_meta_data->>'role' IN ('super_user', 'admin')
ORDER BY os.updated_at DESC;

-- 4. Check recent notifications sent
SELECT 
  type,
  title,
  created_at,
  user_id
FROM notifications
ORDER BY created_at DESC
LIMIT 10;
```

---

## ✅ Checklist

Before testing notifications, ensure:

- [ ] **OneSignal REST API Key** is set in Supabase secrets
- [ ] **OneSignal APP ID** is set in Supabase secrets
- [ ] **Edge functions deployed** (notify-responder-assignment, notify-superusers-critical-report, onesignal-send)
- [ ] **onesignal_subscriptions table exists** and has records
- [ ] **get_super_users() function** exists in database
- [ ] **Mobile app is open** on test device with user logged in
- [ ] **User has allowed notifications** in device settings

---

## 🚨 Common Issues

### "No OneSignal player ID found"
- User needs to open mobile app while logged in
- OneSignal initialization might have failed
- Check mobile app permissions for notifications

### "OneSignal not configured"
- Environment variables not set in Supabase
- Secrets need to be set for each edge function

### "No super users found"
- Check if any users have role 'super_user' or 'admin'
- Check if they have opened the mobile app to register OneSignal player ID

### "OneSignal API error: 400"
- Wrong API key format
- Check if using correct REST API key (not User Auth Key)

---

## 📞 Support

If notifications still don't work after checking all above:

1. Check Supabase Edge Function logs for errors
2. Check mobile app console for OneSignal initialization errors
3. Verify OneSignal Dashboard shows your app ID
4. Test with OneSignal's test notification feature first

**Current Status:** Code is correct, issue is likely configuration or deployment related.

