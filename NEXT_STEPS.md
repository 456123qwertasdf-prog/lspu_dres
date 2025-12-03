# 🚀 NEXT STEPS - Quick Action Guide

## ✅ What's Already Done

- ✅ **33 Edge Functions deployed** to Supabase
- ✅ **Notification functions** are live
- ✅ **Mobile app code** updated
- ✅ **SQL script** ready to run

---

## ⚠️ DO THIS NOW (In Order)

### Step 1: Run SQL Script (5 minutes)

**File:** `DEPLOY_NOTIFICATIONS_DATABASE.sql`

1. Open Supabase SQL Editor: https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/sql/new
2. Copy **entire contents** of `DEPLOY_NOTIFICATIONS_DATABASE.sql`
3. Paste into editor
4. Click **RUN** button
5. Verify you see "✅" success messages

**What it creates:**
- `onesignal_subscriptions` table
- RLS security policies
- `get_super_users()` function

---

### Step 2: Verify OneSignal Keys (2 minutes)

1. Go to: https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/settings/functions
2. Check "Edge Function Secrets" section
3. Verify these exist:
   - `ONESIGNAL_APP_ID` = `8d6aa625-a650-47ac-b9ba-00a247840952`
   - `ONESIGNAL_REST_API_KEY` = Your REST API key

**If missing:**
- Get REST API Key from: https://app.onesignal.com/ → Settings → Keys & IDs
- Add in Supabase dashboard or run:
  ```powershell
  supabase secrets set ONESIGNAL_REST_API_KEY=your_key_here
  ```

---

### Step 3: Test the System

#### Test 1: Open Mobile App
1. Open the mobile app on your device
2. Login as any user
3. Check logs for: `✅ OneSignal Player ID saved`

#### Test 2: Verify Database
Run this in SQL Editor:
```sql
SELECT u.email, os.player_id, os.updated_at
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
ORDER BY os.updated_at DESC;
```

Should show users with player IDs.

#### Test 3: Send Test Notification
1. Assign a responder to a report (web app)
2. Check if they receive notification (mobile)

---

## 📋 Quick Checklist

- [ ] Run `DEPLOY_NOTIFICATIONS_DATABASE.sql` 
- [ ] Verify OneSignal secrets exist
- [ ] Open mobile app and login
- [ ] Check player ID saved in database
- [ ] Test sending notification

---

## 🆘 If Something Doesn't Work

### No table 'onesignal_subscriptions'
→ You didn't run the SQL script yet. Go to Step 1.

### No notifications received
→ Check OneSignal secrets. Go to Step 2.

### "Permission denied" errors
→ RLS policies not set. Rerun SQL script.

---

## 📞 Quick Links

- **Run SQL:** https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/sql/new
- **Check Secrets:** https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/settings/functions
- **View Logs:** https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/logs
- **OneSignal:** https://app.onesignal.com/

---

## ✅ That's It!

Once you complete Steps 1-3, your notification system will be fully deployed and working! 🎉


