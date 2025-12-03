# Fix Super User Notification Errors

## Problem
The `notify-superusers-critical-report` Edge Function is failing with error:
```
PGRST202: Searched for the function public.get_super_users without parameters
```

This is because the required database functions don't exist yet.

### Additional Issue Fixed
The initial migration tried to access `onesignal_player_id` from `auth.users`, but OneSignal player IDs are actually stored in the `onesignal_subscriptions` table with the column name `player_id`. The fixed version correctly joins with this table.

## Solution

### Step 1: Apply the Database Migration

Run this SQL in your Supabase SQL Editor:

```sql
-- Go to: https://supabase.com/dashboard/project/YOUR_PROJECT/sql/new
-- Then run the migration file:
```

Or use the Supabase CLI to apply the migration:

```bash
# Navigate to your project directory
cd c:\Users\Ducay\Desktop\lspu_dres

# Apply the migration
supabase db push
```

The migration file has been created at:
`supabase/migrations/20250203000000_add_super_user_functions.sql`

### Step 2: What This Migration Does

This migration creates two essential functions:

#### 1. `get_super_users()`
Returns all users with `super_user` or `admin` roles, including:
- User ID
- Email
- OneSignal Player ID (for push notifications)
- User metadata

#### 2. `get_users_by_role(role_names)`
Accepts an array of role names and returns matching users.

Example usage:
```sql
-- Get all super users
SELECT * FROM get_super_users();

-- Get users by specific roles
SELECT * FROM get_users_by_role(ARRAY['super_user', 'admin']);
```

### Step 3: Verify the Fix

After applying the migration:

1. **Test in SQL Editor:**
```sql
-- Should return your super users
SELECT * FROM get_super_users();
```

2. **Test the Edge Function:**
   - Submit a new critical/high priority report
   - Check the Edge Function logs (https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/functions/notify-superusers-critical-report/logs)
   - You should see: ✅ "Critical report notification sent to X super users"

3. **Check OneSignal Player IDs:**
   - Make sure your super users have OneSignal Player IDs set
   - These are stored in the `onesignal_subscriptions` table
   - Player IDs are automatically registered when users log in via the mobile app
   
```sql
-- Check which super users have OneSignal configured
SELECT 
  u.email,
  u.raw_user_meta_data->>'role' as role,
  os.player_id,
  os.platform,
  os.updated_at
FROM auth.users u
LEFT JOIN onesignal_subscriptions os ON os.user_id = u.id
WHERE u.raw_user_meta_data->>'role' IN ('super_user', 'admin')
ORDER BY u.email;
```

**Note:** Users can have multiple player IDs (one per device). This is normal if they use the app on multiple devices.

### Step 4: If You Still See "No super users found"

This means either:

#### A. No super users exist in your system
Create a super user:
```sql
-- Update an existing user to super_user role
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"super_user"'
)
WHERE email = 'your-admin-email@example.com';
```

#### B. Super users don't have OneSignal Player IDs
- Super users need to log in via the mobile app to get a OneSignal Player ID
- The app automatically registers the device for push notifications on login
- Check if they have player IDs:
```sql
SELECT 
  u.email,
  COUNT(os.player_id) as device_count
FROM auth.users u
LEFT JOIN onesignal_subscriptions os ON os.user_id = u.id
WHERE u.raw_user_meta_data->>'role' IN ('super_user', 'admin')
GROUP BY u.email;
```
- If `device_count` is 0, the super user hasn't logged in via mobile yet

### Step 5: Expected Workflow

After the fix, when a critical report is submitted:

1. **classify-image** function analyzes the image
2. If report is CRITICAL/HIGH priority:
   - Calls `notify-superusers-critical-report` function
3. **notify-superusers-critical-report** function:
   - Fetches all super users using `get_super_users()`
   - Filters to users with OneSignal Player IDs
   - Sends push notifications via OneSignal
   - Creates database notifications

## Quick Apply (Copy-Paste to SQL Editor)

If you prefer to manually run the SQL, here it is:

```sql
-- Create function to get all super users and admins
-- Note: OneSignal player IDs are stored in the onesignal_subscriptions table
CREATE OR REPLACE FUNCTION public.get_super_users()
RETURNS TABLE (
  id uuid,
  email text,
  onesignal_player_id text,
  raw_user_meta_data jsonb
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT DISTINCT
    u.id,
    u.email,
    os.player_id as onesignal_player_id,
    u.raw_user_meta_data
  FROM auth.users u
  LEFT JOIN public.onesignal_subscriptions os ON os.user_id = u.id
  WHERE u.raw_user_meta_data->>'role' IN ('super_user', 'admin')
  AND u.deleted_at IS NULL;
$$;

-- Create function to get users by specific roles
CREATE OR REPLACE FUNCTION public.get_users_by_role(role_names text[])
RETURNS TABLE (
  id uuid,
  email text,
  onesignal_player_id text,
  role text
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT DISTINCT
    u.id,
    u.email,
    os.player_id as onesignal_player_id,
    u.raw_user_meta_data->>'role' as role
  FROM auth.users u
  LEFT JOIN public.onesignal_subscriptions os ON os.user_id = u.id
  WHERE u.raw_user_meta_data->>'role' = ANY(role_names)
  AND u.deleted_at IS NULL;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_super_users() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_super_users() TO service_role;
GRANT EXECUTE ON FUNCTION public.get_super_users() TO anon;

GRANT EXECUTE ON FUNCTION public.get_users_by_role(text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_users_by_role(text[]) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_users_by_role(text[]) TO anon;
```

## Summary

✅ **Created migration file:** `supabase/migrations/20250203000000_add_super_user_functions.sql`

🔧 **What to do:**
1. Apply the migration via SQL Editor or `supabase db push`
2. Verify super users exist and have OneSignal Player IDs
3. Test by submitting a critical report
4. Check Edge Function logs to confirm notifications are sent

🎯 **Expected result:** Super users will receive push notifications when critical/high priority reports are submitted.

