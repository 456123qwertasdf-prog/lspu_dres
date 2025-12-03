# Deploy Fixed Super User Notification Function

## What Was Fixed

### The Bug 🐛
The Edge Function was calling `get_super_users()` successfully but then **completely ignoring the result** and querying a wrong table instead.

**Before (Buggy Code):**
```typescript
// Line 84: Gets super users ✅
const { data: superUsers } = await supabaseClient.rpc('get_super_users')

// Line 110: BUT THEN IGNORES IT! ❌
const { data: adminUsers } = await supabaseClient
  .from('users')  // Wrong table!
  .select('id, email, onesignal_player_id')  // Wrong column!
```

**After (Fixed Code):**
```typescript
// Get super users with OneSignal player IDs
const { data: superUsers } = await supabaseClient.rpc('get_super_users')

// Filter to only users with OneSignal player IDs ✅
const targetUsers = superUsers.filter(user => 
  user.onesignal_player_id !== null && user.onesignal_player_id !== ''
)
```

## How to Deploy

### Option 1: Deploy via Supabase CLI (Recommended)

```powershell
# Navigate to your project
cd C:\Users\Ducay\Desktop\lspu_dres

# Deploy the specific function
supabase functions deploy notify-superusers-critical-report
```

### Option 2: Deploy via Supabase Dashboard

1. **Go to Edge Functions:**
   https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/functions/notify-superusers-critical-report/code

2. **Update the Code:**
   - Click the "Code" tab
   - Copy the entire content from: `lspu_dres/supabase/functions/notify-superusers-critical-report/index.ts`
   - Paste it into the dashboard editor
   - Click "Deploy"

## Test the Fix

### Step 1: Submit a Critical Report

Submit a report that will be classified as CRITICAL or HIGH priority (e.g., medical emergency, fire, etc.)

### Step 2: Check the Logs

Go to: https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/functions/notify-superusers-critical-report/logs

You should see:
```
✅ Found X super user records
✅ Found 1 super users with OneSignal player IDs
✅ Critical report notification sent to 1 super users/admins
```

### Step 3: Verify OneSignal Sent

Check your OneSignal dashboard:
https://dashboard.onesignal.com/apps/8d6aa625-a650-47ac-b9ba-00a247840952/notifications

You should see a new notification sent to 1 recipient.

### Step 4: Check Mobile Device

The super user (`superuser@lspu-dres.com`) should receive a push notification on their device!

## Expected Behavior After Fix

### Current Super Users Status:
- ✅ `superuser@lspu-dres.com` - Will receive notifications (1 device registered)
- ❌ `admin@demo.com` - Will NOT receive notifications (0 devices registered)

### When Critical Report is Submitted:

1. **classify-image** function analyzes the report
2. If CRITICAL/HIGH priority → calls **notify-superusers-critical-report**
3. **notify-superusers-critical-report** function:
   - ✅ Calls `get_super_users()` → Returns 2 users
   - ✅ Filters to users with player IDs → 1 user (`superuser@lspu-dres.com`)
   - ✅ Sends OneSignal push notification → 1 device
   - ✅ Creates database notification
   - ✅ Logs: "Critical report notification sent to 1 super users/admins"

## Troubleshooting

### If you still see "No super users with OneSignal player IDs found"

1. **Check if function deployed:**
```powershell
supabase functions list
```

2. **Verify deployment timestamp** - should be recent

3. **Check logs for "Found X super user records"** - if you don't see this, the function didn't update

4. **Redeploy:**
```powershell
supabase functions deploy notify-superusers-critical-report --no-verify-jwt
```

### If admin@demo.com wants to receive notifications

They need to:
1. Install the mobile app
2. Log in with `admin@demo.com`
3. App will automatically register their device
4. Check registration:
```sql
SELECT * FROM onesignal_subscriptions 
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'admin@demo.com');
```

## Summary of All Fixes Applied

1. ✅ Created `get_super_users()` database function
2. ✅ Created `get_users_by_role()` database function
3. ✅ Fixed SQL to join with `onesignal_subscriptions` table
4. ✅ Fixed Edge Function to actually use the RPC results
5. ✅ Removed redundant queries to wrong tables
6. ✅ Added better logging for debugging

**Next:** Deploy the Edge Function and test! 🚀

