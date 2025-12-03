-- Verify OneSignal Setup After Deployment
-- Run this in Supabase SQL Editor to check if everything is ready for notifications

-- ========================================
-- 1. CHECK IF ONESIGNAL_SUBSCRIPTIONS TABLE EXISTS
-- ========================================
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'onesignal_subscriptions'
    ) THEN '✅ onesignal_subscriptions table exists'
    ELSE '❌ onesignal_subscriptions table MISSING - needs to be created'
  END as table_status;

-- ========================================
-- 2. CHECK TABLE STRUCTURE
-- ========================================
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'onesignal_subscriptions'
ORDER BY ordinal_position;

-- ========================================
-- 3. COUNT REGISTERED USERS (Will be 0 if you deleted all data)
-- ========================================
SELECT 
  COUNT(*) as total_registered_users,
  COUNT(DISTINCT user_id) as unique_users,
  MAX(updated_at) as last_registration
FROM onesignal_subscriptions;

-- ========================================
-- 4. CHECK REGISTERED USERS BY ROLE
-- ========================================
SELECT 
  COALESCE(u.raw_user_meta_data->>'role', 'no_role') as role,
  COUNT(DISTINCT os.user_id) as user_count,
  COUNT(os.player_id) as subscription_count
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
GROUP BY u.raw_user_meta_data->>'role'
ORDER BY user_count DESC;

-- ========================================
-- 5. CHECK SUPER USERS (Who can receive critical report notifications)
-- ========================================
SELECT 
  u.email,
  u.raw_user_meta_data->>'role' as role,
  os.player_id,
  os.updated_at as registered_at
FROM auth.users u
LEFT JOIN onesignal_subscriptions os ON u.id = os.user_id
WHERE u.raw_user_meta_data->>'role' IN ('super_user', 'admin')
ORDER BY os.updated_at DESC NULLS LAST;

-- ========================================
-- 6. CHECK GET_SUPER_USERS FUNCTION EXISTS
-- ========================================
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT FROM information_schema.routines 
      WHERE routine_schema = 'public' 
      AND routine_name = 'get_super_users'
    ) THEN '✅ get_super_users() function exists'
    ELSE '❌ get_super_users() function MISSING - needs to be created'
  END as function_status;

-- ========================================
-- 7. CHECK FOR DUPLICATE REGISTRATIONS (Same user, multiple devices)
-- ========================================
SELECT 
  u.email,
  u.raw_user_meta_data->>'role' as role,
  COUNT(*) as device_count,
  array_agg(os.player_id) as player_ids,
  MAX(os.updated_at) as last_updated
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
GROUP BY u.id, u.email, u.raw_user_meta_data->>'role'
HAVING COUNT(*) > 1
ORDER BY device_count DESC;

-- ========================================
-- 8. CHECK RECENT NOTIFICATIONS (Database notifications)
-- ========================================
SELECT 
  n.type,
  n.title,
  n.created_at,
  n.read,
  u.email,
  u.raw_user_meta_data->>'role' as user_role
FROM notifications n
JOIN auth.users u ON n.user_id = u.id
ORDER BY n.created_at DESC
LIMIT 10;

-- ========================================
-- 9. CHECK ALL USERS WHO NEED TO RE-REGISTER
-- ========================================
SELECT 
  u.email,
  u.raw_user_meta_data->>'role' as role,
  u.created_at as account_created,
  CASE 
    WHEN os.user_id IS NOT NULL THEN '✅ Registered'
    ELSE '⏳ Needs to open app'
  END as notification_status
FROM auth.users u
LEFT JOIN onesignal_subscriptions os ON u.id = os.user_id
WHERE u.raw_user_meta_data->>'role' IS NOT NULL
ORDER BY 
  CASE WHEN os.user_id IS NULL THEN 0 ELSE 1 END,
  u.raw_user_meta_data->>'role';

-- ========================================
-- SUMMARY
-- ========================================
SELECT 
  '📊 ONESIGNAL SETUP SUMMARY' as summary,
  (SELECT COUNT(*) FROM auth.users WHERE raw_user_meta_data->>'role' IS NOT NULL) as total_users,
  (SELECT COUNT(DISTINCT user_id) FROM onesignal_subscriptions) as users_registered,
  (SELECT COUNT(*) FROM auth.users WHERE raw_user_meta_data->>'role' IN ('super_user', 'admin')) as super_users,
  (SELECT COUNT(DISTINCT os.user_id) FROM onesignal_subscriptions os JOIN auth.users u ON os.user_id = u.id WHERE u.raw_user_meta_data->>'role' IN ('super_user', 'admin')) as super_users_registered;

