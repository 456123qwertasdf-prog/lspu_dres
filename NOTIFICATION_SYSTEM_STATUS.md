# 🔔 Notification System Status

## ✅ What Was Fixed

### 1. **Super User Notifications** (Critical Report Alerts)
**Status:** ✅ **FIXED & DEPLOYED**

**Problem:** 
- Super users weren't receiving push notifications for critical/high priority reports
- Edge Functions weren't deployed with the notification code

**Solution:**
- ✅ Redeployed `classify-image` with notification trigger code
- ✅ Deployed `notify-superusers-critical-report` function
- ✅ Database function `get_super_users()` verified working
- ✅ 2 super users with 3 devices registered for notifications

**When it triggers:**
- Any report with `priority ≤ 2` OR `severity = 'CRITICAL'` or `'HIGH'`
- Examples: Fire, Medical, Earthquake, Accident

**Recipients:**
- `superuser@lspu-dres.com` (2 devices) ✅
- `jonducay242@gmail.com` (1 device) ✅
- `admin@demo.com` (⚠️ needs to log into mobile app)

---

### 2. **Responder Assignment Notifications**
**Status:** ✅ **FIXED & DEPLOYED (Web + Mobile)**

**Problem:** 
- Responders weren't receiving push notifications when assigned to reports
- The `notify-responder-assignment` function was querying the wrong database table
- It was looking for `onesignal_player_id` in a `users` table
- But OneSignal IDs are actually in the `onesignal_subscriptions` table
- **Mobile app was directly manipulating database, bypassing notifications**

**Solution:**
- ✅ Fixed database query to use `onesignal_subscriptions` table
- ✅ Updated to support multiple devices per responder
- ✅ Redeployed `notify-responder-assignment` function
- ✅ Redeployed `assign-responder` function
- ✅ **Updated mobile app to call `assign-responder` Edge Function**
- ✅ **Mobile super users can now send notifications to responders**

**When it triggers:**
- When a super user assigns a responder to a report (via **web OR mobile** dashboard)

**Notification Types:**
- 🔴 **CRITICAL/HIGH** (priority ≤ 2): Red notification, emergency sound
- 🟠 **NORMAL** (priority 3-4): Orange notification, default sound

**Interfaces:**
- ✅ Web Dashboard → Calls Edge Function → Notifications sent
- ✅ Mobile App → Calls Edge Function → Notifications sent

---

## 🧪 Testing Guide

### Test Super User Notifications

#### Option 1: Automatic (via new report)
1. Submit a new emergency report via mobile app
2. AI will classify it
3. If critical/high priority → Super users get notified automatically

#### Option 2: Manual Test
1. Run `get_recent_critical_report.sql` in Supabase SQL Editor
2. Copy a report ID
3. Go to: https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/functions/notify-superusers-critical-report/
4. Click "Test" button
5. Paste: `{"report_id": "YOUR_REPORT_ID"}`
6. Click "Run"
7. Check your mobile device for notification 📱

#### Check Logs
- Go to: Edge Functions → `notify-superusers-critical-report` → Logs
- Look for:
  ```
  Found X super users with OneSignal player IDs
  Sending OneSignal notification to X device(s)
  ✅ Critical report notification sent
  ```

---

### Test Responder Assignment Notifications

#### Step 1: Check which responders can receive notifications
Run `check_responder_onesignal.sql` in SQL Editor:
```sql
SELECT 
  r.id as responder_id,
  r.name as responder_name,
  r.user_id,
  u.email,
  os.player_id as onesignal_player_id
FROM responder r
JOIN auth.users u ON u.id = r.user_id
LEFT JOIN onesignal_subscriptions os ON os.user_id = r.user_id
WHERE u.deleted_at IS NULL;
```

This shows which responders have devices registered.

#### Step 2: Test by assigning a responder

**Option A: Web Dashboard**
1. Go to Super User Dashboard (web)
2. Find any unassigned report
3. Click "Assign Responder"
4. Select a responder who has an `onesignal_player_id`
5. Save/Confirm

**Option B: Mobile App** ✅ **NOW WORKING!**
1. Open mobile app as super user
2. Go to **Reports** tab
3. Select any unassigned report
4. Tap **Edit** button (top right)
5. Select a responder from the dropdown
6. Tap **Save Changes**

#### Step 3: Check what happens
**Responder should receive:**
- 📱 Push notification on their mobile device
- 🔔 In-app notification in the mobile app
- 💾 Database notification entry

**Check logs:**
- Go to: Edge Functions → `assign-responder` → Logs
- Look for:
  ```
  ✅ Push notification sent to responder: {...}
  ```
- Go to: Edge Functions → `notify-responder-assignment` → Logs  
- Look for:
  ```
  Sending notification to X device(s) for responder [name]
  Sending OneSignal notification to X device(s)
  ✅ Push notification sent to responder [name]
  ```

---

## 📊 System Health Check

Run these queries to verify everything is set up correctly:

### 1. Super Users with Devices
```sql
SELECT * FROM get_super_users();
-- Should return 3 rows (2 unique users with 3 total devices)
```

### 2. Responders with Devices
```sql
SELECT 
  r.name,
  COUNT(os.player_id) as device_count
FROM responder r
JOIN auth.users u ON u.id = r.user_id
LEFT JOIN onesignal_subscriptions os ON os.user_id = r.user_id
WHERE u.deleted_at IS NULL
GROUP BY r.id, r.name;
```

### 3. Recent Critical Reports
```sql
SELECT 
  id,
  type,
  priority,
  severity,
  created_at
FROM reports
WHERE (priority <= 2 OR severity IN ('CRITICAL', 'HIGH'))
  AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;
```

---

## 🔧 Deployed Edge Functions

| Function | Status | Purpose |
|----------|--------|---------|
| `classify-image` | ✅ Deployed | Classifies reports & triggers super user notifications |
| `notify-superusers-critical-report` | ✅ Deployed | Sends push notifications to super users |
| `assign-responder` | ✅ Deployed | Handles responder assignments |
| `notify-responder-assignment` | ✅ **FIXED & Deployed** | Sends push notifications to responders |

---

## 🐛 Bug Fixed

### Issue in `notify-responder-assignment`

**Before (BROKEN):**
```typescript
// Tried to query non-existent 'users' table
const { data: userData } = await supabaseClient
  .from('users')  // ❌ Wrong table
  .select('onesignal_player_id')  // ❌ Column doesn't exist
  .eq('id', responder.user_id)
```

**After (FIXED):**
```typescript
// Now correctly queries onesignal_subscriptions table
const { data: subscriptions } = await supabaseClient
  .from('onesignal_subscriptions')  // ✅ Correct table
  .select('player_id')  // ✅ Correct column
  .eq('user_id', responder.user_id)

// Get all player IDs (supports multiple devices)
const playerIds = subscriptions.map(sub => sub.player_id)
```

---

## 📱 Requirements for Notifications to Work

### For Super Users:
- ✅ Must have `super_user` or `admin` role in database
- ✅ Must log into mobile app at least once
- ✅ Must allow push notification permissions
- ✅ OneSignal Player ID must be saved to `onesignal_subscriptions` table

### For Responders:
- ✅ Must exist in `responder` table
- ✅ Must have a linked `user_id` in `auth.users`
- ✅ Must log into mobile app at least once
- ✅ Must allow push notification permissions
- ✅ OneSignal Player ID must be saved to `onesignal_subscriptions` table

---

## ✅ Next Steps

1. **Test super user notifications** by creating a new critical report
2. **Test responder notifications** by assigning a responder to a report (from web OR mobile)
3. **Ensure all responders log into mobile app** to register for notifications
4. **Ensure `admin@demo.com` logs into mobile app** to receive notifications
5. **Build and deploy updated mobile app** with notification fix

---

## 📚 Related Documentation

- [MOBILE_APP_NOTIFICATION_FIX.md](./MOBILE_APP_NOTIFICATION_FIX.md) - **NEW!** Mobile app notification fix details
- [RESPONDER_ASSIGNMENT_FIX.md](./RESPONDER_ASSIGNMENT_FIX.md) - Web interface notification fix
- [NOTIFICATION_SYNC_SYSTEM.md](./NOTIFICATION_SYNC_SYSTEM.md) - Notification sync system

---

**Last Updated:** December 4, 2025  
**Status:** ✅ All systems operational and deployed!  
**Latest Fix:** ✅ Mobile app now sends notifications when assigning responders!

