-- Simple OneSignal Verification (No Errors)
-- Run this in Supabase SQL Editor

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
    ELSE '❌ onesignal_subscriptions table MISSING'
  END as status;

-- ========================================
-- 2. COUNT REGISTERED USERS
-- ========================================
SELECT 
  COUNT(*) as total_subscriptions,
  COUNT(DISTINCT user_id) as unique_users,
  MAX(updated_at) as last_registration
FROM onesignal_subscriptions;

-- ========================================
-- 3. VIEW ALL REGISTERED USERS
-- ========================================
SELECT 
  u.email,
  u.raw_user_meta_data->>'role' as role,
  os.player_id,
  os.updated_at as registered_at
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
ORDER BY os.updated_at DESC;

-- ========================================
-- 4. CHECK SUPER USERS WITH/WITHOUT ONESIGNAL
-- ========================================
SELECT 
  u.email,
  u.raw_user_meta_data->>'role' as role,
  CASE 
    WHEN os.player_id IS NOT NULL THEN '✅ Registered'
    ELSE '⏳ Needs to open app'
  END as status,
  os.player_id,
  os.updated_at as registered_at
FROM auth.users u
LEFT JOIN onesignal_subscriptions os ON u.id = os.user_id
WHERE u.raw_user_meta_data->>'role' IN ('super_user', 'admin')
ORDER BY os.updated_at DESC NULLS LAST;

-- ========================================
-- 5. SUMMARY - WHO NEEDS TO REGISTER
-- ========================================
SELECT 
  COUNT(*) FILTER (WHERE u.raw_user_meta_data->>'role' IS NOT NULL) as total_users,
  COUNT(*) FILTER (WHERE os.user_id IS NOT NULL) as users_registered,
  COUNT(*) FILTER (WHERE u.raw_user_meta_data->>'role' IN ('super_user', 'admin')) as total_super_users,
  COUNT(*) FILTER (WHERE u.raw_user_meta_data->>'role' IN ('super_user', 'admin') AND os.user_id IS NOT NULL) as super_users_registered
FROM auth.users u
LEFT JOIN onesignal_subscriptions os ON u.id = os.user_id
WHERE u.raw_user_meta_data->>'role' IS NOT NULL;

-- ========================================
-- 6. LIST ALL USERS WHO NEED TO OPEN THE APP
-- ========================================
SELECT 
  u.email,
  u.raw_user_meta_data->>'role' as role,
  u.created_at as account_created,
  '⏳ Needs to open mobile app to register for notifications' as action_needed
FROM auth.users u
LEFT JOIN onesignal_subscriptions os ON u.id = os.user_id
WHERE u.raw_user_meta_data->>'role' IS NOT NULL
  AND os.user_id IS NULL
ORDER BY u.raw_user_meta_data->>'role', u.email;

