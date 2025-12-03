# 🚀 Supabase Deployment Complete

## ✅ What Was Deployed

### 1. Edge Functions Deployed (via CLI)

All notification-related edge functions have been successfully deployed to Supabase:

| Function | Status | Purpose |
|----------|--------|---------|
| **notify-responder-assignment** | ✅ Deployed | Sends push notifications when responders are assigned to reports |
| **notify-superusers-critical-report** | ✅ Deployed | Notifies super users about critical/high priority reports |
| **onesignal-send** | ✅ Deployed | Core OneSignal push notification handler |
| **announcement-notify** | ✅ Deployed | Handles announcement notifications to all users |

**Dashboard Link:** https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/functions

---

## 📋 Database Setup Required

### Run the SQL Script

You need to run **one** SQL script in the Supabase SQL Editor to complete the setup:

**File:** `DEPLOY_NOTIFICATIONS_DATABASE.sql`

**How to run:**
1. Go to: https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/sql/new
2. Copy the entire contents of `DEPLOY_NOTIFICATIONS_DATABASE.sql`
3. Paste into the SQL Editor
4. Click **RUN** button

**What it does:**
- ✅ Creates/verifies `onesignal_subscriptions` table
- ✅ Sets up proper RLS (Row Level Security) policies
- ✅ Creates `get_super_users()` database function
- ✅ Verifies everything is working
- ✅ Shows current subscription count

---

## ⚙️ Environment Variables Check

Make sure these are set in Supabase:

### Required for OneSignal:
```bash
ONESIGNAL_APP_ID=8d6aa625-a650-47ac-b9ba-00a247840952
ONESIGNAL_REST_API_KEY=<your-onesignal-rest-api-key>
```

### How to verify/set:

**Option 1: Via Dashboard**
1. Go to: https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/settings/functions
2. Check "Edge Function Secrets" section
3. Add secrets if missing

**Option 2: Via CLI**
```powershell
supabase secrets set ONESIGNAL_APP_ID=8d6aa625-a650-47ac-b9ba-00a247840952
supabase secrets set ONESIGNAL_REST_API_KEY=your_actual_key_here
```

**How to get the REST API Key:**
1. Go to OneSignal Dashboard: https://app.onesignal.com/
2. Select your app
3. Go to Settings → Keys & IDs
4. Copy the "REST API Key" (NOT User Auth Key)

---

## 📱 Mobile App Changes

The mobile app `onesignal_service.dart` has been updated with:

- ✅ Improved OneSignal initialization
- ✅ Subscription observer for real-time player ID updates
- ✅ Retry logic for player ID registration
- ✅ Better error handling and logging
- ✅ Save to both `users` and `onesignal_subscriptions` tables

**Status:** Modified but not committed (as per your git status)

---

## 🧪 Testing Checklist

### Before Testing:
- [ ] SQL script run successfully (`DEPLOY_NOTIFICATIONS_DATABASE.sql`)
- [ ] Edge functions deployed (✅ DONE)
- [ ] OneSignal environment variables set
- [ ] Mobile app rebuilt with updated `onesignal_service.dart`

### Test 1: User Registration
1. Open mobile app
2. Login as any user
3. Check logs for: `✅ OneSignal Player ID saved to Supabase`
4. Verify in database:
```sql
SELECT u.email, os.player_id, os.updated_at
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
ORDER BY os.updated_at DESC;
```

### Test 2: Responder Assignment Notification
1. Login as admin in web app
2. Assign a responder to a report
3. **Expected:** Responder receives push notification
4. Check logs: `supabase functions logs notify-responder-assignment`

### Test 3: Critical Report Notification
1. Submit a high priority report
2. **Expected:** Super users receive push notification
3. Check logs: `supabase functions logs notify-superusers-critical-report`

### Test 4: Announcement Notification
1. Create an announcement as admin
2. **Expected:** Target users receive push notification
3. Check logs: `supabase functions logs onesignal-send`

---

## 🔍 Diagnostic Queries

Run these in Supabase SQL Editor to verify everything:

```sql
-- Check total subscriptions
SELECT COUNT(*) as total_subscriptions 
FROM onesignal_subscriptions;

-- Check subscriptions by role
SELECT 
  u.raw_user_meta_data->>'role' as role,
  COUNT(*) as count
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
GROUP BY u.raw_user_meta_data->>'role';

-- Check super users with OneSignal
SELECT 
  u.email,
  u.raw_user_meta_data->>'role' as role,
  os.player_id,
  os.updated_at
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
WHERE u.raw_user_meta_data->>'role' IN ('super_user', 'admin')
ORDER BY os.updated_at DESC;

-- View recent notifications
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

## 🐛 Troubleshooting

### "No OneSignal player ID found"
- **Cause:** User hasn't opened the mobile app
- **Solution:** Have user open app and login

### "OneSignal not configured"
- **Cause:** Environment variables not set
- **Solution:** Set `ONESIGNAL_APP_ID` and `ONESIGNAL_REST_API_KEY` in Supabase

### "Failed to save to subscriptions table"
- **Cause:** RLS policies not set up correctly
- **Solution:** Run `DEPLOY_NOTIFICATIONS_DATABASE.sql`

### "OneSignal API error: 400"
- **Cause:** Wrong API key format
- **Solution:** Use REST API Key, not User Auth Key

### Notifications not received on mobile
- **Cause:** Device notification settings
- **Solution:** Check device Settings → Apps → LSPU DRES → Enable notifications

---

## 📊 Deployment Summary

| Component | Status | Action Required |
|-----------|--------|----------------|
| Edge Functions | ✅ Deployed | None |
| Database Schema | ⏳ Pending | Run SQL script |
| RLS Policies | ⏳ Pending | Run SQL script |
| Database Functions | ⏳ Pending | Run SQL script |
| Environment Variables | ⚠️ Verify | Check/set in dashboard |
| Mobile App | ✅ Updated | Build and test |

---

## 🎯 Next Steps

1. **Run SQL Script:** Copy and run `DEPLOY_NOTIFICATIONS_DATABASE.sql` in Supabase SQL Editor
2. **Verify Environment Variables:** Check OneSignal keys are set
3. **Test Mobile App:** Open app and verify player ID registration
4. **Test Notifications:** Try all notification types
5. **Monitor Logs:** Watch Supabase function logs for errors

---

## 📞 Support Resources

- **Supabase Dashboard:** https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld
- **Edge Functions:** https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/functions
- **SQL Editor:** https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/sql
- **OneSignal Dashboard:** https://app.onesignal.com/

---

## ✅ Deployment Checklist

- [x] Edge functions deployed via CLI
- [x] SQL deployment script created
- [x] Mobile app OneSignal service updated
- [x] Deployment documentation created
- [ ] SQL script run in Supabase (DO THIS NEXT)
- [ ] Environment variables verified
- [ ] Mobile app tested
- [ ] Notifications tested

**Status:** Edge functions deployed ✅ | Database setup pending ⏳


