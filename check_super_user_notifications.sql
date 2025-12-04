-- ============================================
-- DIAGNOSTIC SCRIPT FOR SUPER USER NOTIFICATIONS
-- Run this in your Supabase SQL Editor
-- ============================================

-- Step 1: Check if get_super_users function exists
SELECT 
  routine_name, 
  routine_type,
  specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name = 'get_super_users';

-- Step 2: Check for super users in auth.users
SELECT 
  id,
  email,
  raw_user_meta_data->>'role' as role,
  created_at
FROM auth.users 
WHERE raw_user_meta_data->>'role' IN ('super_user', 'admin')
  AND deleted_at IS NULL;

-- Step 3: Check OneSignal subscriptions for super users
SELECT 
  u.email,
  u.raw_user_meta_data->>'role' as role,
  os.player_id,
  os.created_at,
  os.updated_at
FROM auth.users u
LEFT JOIN onesignal_subscriptions os ON os.user_id = u.id
WHERE u.raw_user_meta_data->>'role' IN ('super_user', 'admin')
  AND u.deleted_at IS NULL;

-- Step 4: Try calling get_super_users function
SELECT * FROM get_super_users();

-- Step 5: Check recent critical/high priority reports
SELECT 
  id,
  type,
  priority,
  severity,
  created_at,
  status
FROM reports
WHERE (priority <= 2 OR severity IN ('CRITICAL', 'HIGH'))
  AND created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC
LIMIT 10;

-- Step 6: Check all reports to see priority distribution
SELECT 
  type,
  priority,
  severity,
  COUNT(*) as count
FROM reports
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY type, priority, severity
ORDER BY priority, severity;

