# ✅ Notification Functions Deployed Successfully!

## 🚀 Deployed Functions:

1. ✅ **notify-responder-assignment** - Sends notifications when responders are assigned to reports
2. ✅ **notify-superusers-critical-report** - Notifies super users about critical/high priority reports
3. ✅ **onesignal-send** - Handles OneSignal push notifications for announcements
4. ✅ **announcement-notify** - Creates notifications for announcements and calls onesignal-send

**Dashboard Link:**
https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/functions

---

## ⚠️ You Deleted All OneSignal Data - What This Means:

Since you deleted all OneSignal subscriptions, **users need to re-register** by opening the mobile app while logged in.

### What Happens When Users Open the App:

1. ✅ OneSignal SDK initializes automatically
2. ✅ User gets a OneSignal player ID
3. ✅ App saves player ID to `onesignal_subscriptions` table
4. ✅ User can now receive push notifications

---

## 📱 How to Re-Enable Notifications:

### For Each User:

1. **Open the mobile app**
2. **Login** (if not already logged in)
3. **Allow notifications** when prompted
4. **Done!** - User is now registered for notifications

### Check if Users Are Registered:

Run this SQL in Supabase SQL Editor:

```sql
-- Check all registered users
SELECT 
  u.email,
  u.raw_user_meta_data->>'role' as role,
  os.player_id,
  os.updated_at as registered_at
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
ORDER BY os.updated_at DESC;
```

---

## 🧪 Testing Notifications (After Users Re-Register):

### Test 1: Assignment Notification
1. Make sure a **responder** has opened the app
2. **Assign** them to a report in the admin panel
3. **Expected:** Responder receives push notification

### Test 2: Critical Report Notification
1. Make sure **super users** have opened the app
2. **Submit** a high priority report as citizen
3. **Expected:** All super users receive push notification

### Test 3: Announcement Notification
1. Make sure target users have opened the app
2. **Create** an announcement in admin panel
3. **Expected:** Target audience receives push notification

---

## 🔍 Troubleshooting

### "Still no notifications after opening app"

**Check 1: OneSignal Environment Variables**
```bash
# Verify secrets are set in Supabase
# Go to: Supabase Dashboard → Settings → Edge Functions → Environment Variables
```

Required:
- `ONESIGNAL_APP_ID` = `8d6aa625-a650-47ac-b9ba-00a247840952`
- `ONESIGNAL_REST_API_KEY` = Your REST API key from OneSignal dashboard

**Check 2: Mobile App Logs**
- Check if OneSignal initializes: "OneSignal initialized"
- Check if player ID is saved: "Saved OneSignal player ID"

**Check 3: Device Notification Settings**
- Go to device Settings → Apps → LSPU DRES
- Make sure **Notifications** are enabled

**Check 4: Supabase Function Logs**
```bash
# View logs for each function
supabase functions logs notify-responder-assignment
supabase functions logs notify-superusers-critical-report
supabase functions logs onesignal-send
```

Look for errors or "No OneSignal player ID found" messages.

---

## 📊 Database Verification Queries

Run these in Supabase SQL Editor:

```sql
-- 1. Check if onesignal_subscriptions table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'onesignal_subscriptions'
);
-- Should return: true

-- 2. Count registered users by role
SELECT 
  u.raw_user_meta_data->>'role' as role,
  COUNT(*) as registered_users
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
GROUP BY u.raw_user_meta_data->>'role';

-- 3. Check for duplicate subscriptions (same user, different player_ids)
SELECT 
  user_id,
  COUNT(*) as subscription_count
FROM onesignal_subscriptions
GROUP BY user_id
HAVING COUNT(*) > 1;
-- Should be empty or have users who logged in from multiple devices

-- 4. Check recent notifications
SELECT 
  n.type,
  n.title,
  n.created_at,
  u.email
FROM notifications n
JOIN auth.users u ON n.user_id = u.id
ORDER BY n.created_at DESC
LIMIT 10;
```

---

## 🎯 Next Steps:

### Immediate:
1. ✅ **Edge functions deployed** (DONE)
2. ⏳ **Have users open mobile app** to re-register
3. ⏳ **Verify environment variables** are set in Supabase

### Testing:
1. Open mobile app as **responder** → Check if player ID is saved
2. Open mobile app as **super user** → Check if player ID is saved
3. Assign a report → Test responder notification
4. Create announcement → Test announcement notification

### Monitoring:
- Check Supabase function logs regularly
- Monitor `onesignal_subscriptions` table growth
- Test notifications with real devices

---

## ✅ Deployment Status:

**Code:** ✅ Fixed and deployed
**Database:** ⏳ Waiting for users to re-register
**Environment:** ⚠️ Check if OneSignal secrets are set

**Everything is ready! Users just need to open the app to register for notifications again.**

---

## 📞 Support

If notifications still don't work after users open the app:

1. Check Supabase Dashboard → Edge Functions → Logs
2. Look for "OneSignal API error" or "No OneSignal player ID"
3. Verify OneSignal REST API key is correct
4. Check mobile app console for OneSignal initialization errors
5. Test sending notification from OneSignal Dashboard directly

**Dashboard Links:**
- Supabase Functions: https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/functions
- OneSignal Dashboard: https://app.onesignal.com/

