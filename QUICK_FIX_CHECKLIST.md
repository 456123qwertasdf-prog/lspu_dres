# 🚨 QUICK FIX: Notifications Not Working When App is Closed

## Problem
citizendemo account doesn't receive notifications when app is closed (but still logged in).

---

## 🎯 Quick Fix Steps (Do in Order)

### ✅ Step 1: Check if OneSignal Player ID is Saved (2 minutes)

1. Open Supabase SQL Editor
2. Run this query from `DIAGNOSE_CITIZEN_NOTIFICATIONS.sql`:

```sql
SELECT 
  u.email,
  u.raw_user_meta_data->>'role' as role,
  CASE 
    WHEN os.player_id IS NOT NULL THEN '✅ Registered'
    ELSE '❌ NOT REGISTERED - OPEN APP'
  END as status,
  os.player_id
FROM auth.users u
LEFT JOIN onesignal_subscriptions os ON u.id = os.user_id
WHERE u.email LIKE '%demo%' OR u.email LIKE '%citizen%';
```

**If you see ❌ NOT REGISTERED:**
- Open mobile app
- Login as citizendemo
- Wait 10 seconds
- Look for "✅ OneSignal Player ID saved" in app logs
- Run query again

---

### ✅ Step 2: Check OneSignal API Key in Supabase (3 minutes)

1. **Get your OneSignal REST API Key:**
   - Go to https://app.onesignal.com/
   - Settings → Keys & IDs
   - Copy "REST API Key"

2. **Set in Supabase:**

**Option A - Using Supabase CLI (Recommended):**
```bash
supabase secrets set ONESIGNAL_APP_ID=8d6aa625-a650-47ac-b9ba-00a247840952
supabase secrets set ONESIGNAL_REST_API_KEY=your_actual_key_here
```

**Option B - Using Supabase Dashboard:**
- Go to: Project Settings → Edge Functions → Environment Variables
- Add both secrets manually

3. **Verify it worked:**
```bash
supabase secrets list
```

Should show:
```
ONESIGNAL_APP_ID
ONESIGNAL_REST_API_KEY
```

---

### ✅ Step 3: Test the Notification (2 minutes)

**On Mobile Device (citizendemo):**
1. Open app → Login → Press Home button (don't log out)
2. Lock the screen

**On Web Browser (super_user):**
1. Login as super_user
2. Create an announcement:
   - Type: Emergency
   - Target: All
   - Title: "Test Alert"
   - Message: "Testing notifications"
3. Send

**Expected:**
- 📱 Mobile device receives notification
- 🔔 Sound plays
- 📬 Notification appears on lock screen

---

### ✅ Step 4: If Still Not Working - Check Logs (2 minutes)

```bash
# Check announcement function logs
supabase functions logs announcement-notify --limit 10

# Check OneSignal send logs
supabase functions logs onesignal-send --limit 10
```

**Look for:**

✅ **Good Messages:**
```
Found X OneSignal subscriptions
OneSignal notifications sent to X devices
recipients: 1
```

❌ **Problem Messages:**
```
No OneSignal player IDs found
→ Go back to Step 1

ONESIGNAL_REST_API_KEY not configured
→ Go back to Step 2

OneSignal API error: 401
→ Wrong API key, check Step 2

OneSignal API error: 400
→ Using wrong key type (need REST API Key, not User Auth Key)
```

---

### ✅ Step 5: Android Battery Settings (1 minute)

If notifications work when app is open but NOT when closed:

**Disable Battery Optimization:**
1. Settings → Apps → Your App
2. Battery → Battery optimization → Don't optimize
3. Allow background data usage

**For Xiaomi/MIUI:**
- Security → Autostart → Enable for your app

**For Huawei:**
- Battery → App launch → Your app → Manage manually
- Enable all options

---

## 🎯 Success Checklist

Mark each when complete:

- [ ] citizendemo has player_id in database (Step 1)
- [ ] ONESIGNAL_REST_API_KEY is set in Supabase (Step 2)
- [ ] ONESIGNAL_APP_ID is set in Supabase (Step 2)
- [ ] Test notification received on mobile (Step 3)
- [ ] Logs show "recipients: 1" (Step 4)
- [ ] Battery optimization disabled (Step 5)

---

## 🔧 Most Common Issues & Fixes

### Issue: "No player_id in database"
**Fix:** Open app → Wait 10 seconds → Check logs for "OneSignal Player ID saved"

### Issue: "ONESIGNAL_REST_API_KEY not configured"
**Fix:** 
```bash
supabase secrets set ONESIGNAL_REST_API_KEY=your_key_here
```

### Issue: "Notifications work when app open, not closed"
**Fix:** Settings → Apps → Battery → Don't optimize

### Issue: "OneSignal API error: 401"
**Fix:** Wrong API key. Get REST API Key from OneSignal dashboard (not User Auth Key)

---

## 📞 Quick Debug Commands

### Check citizendemo registration:
```sql
SELECT u.email, os.player_id, os.updated_at
FROM auth.users u
LEFT JOIN onesignal_subscriptions os ON u.id = os.user_id
WHERE u.email LIKE '%demo%';
```

### View recent announcements:
```sql
SELECT id, title, target_audience, created_at 
FROM announcements 
ORDER BY created_at DESC 
LIMIT 5;
```

### Check edge function logs:
```bash
supabase functions logs onesignal-send --limit 5
```

---

## ⏱️ Total Time: ~10 minutes

If you complete all steps and it still doesn't work, check `FIX_BACKGROUND_NOTIFICATIONS.md` for detailed troubleshooting.

---

**Quick Reference Files:**
- `DIAGNOSE_CITIZEN_NOTIFICATIONS.sql` - Full diagnostic queries
- `FIX_BACKGROUND_NOTIFICATIONS.md` - Detailed troubleshooting guide
- `CHECK_NOTIFICATIONS_TROUBLESHOOTING.md` - Complete notification system guide

