-- ============================================
-- SIMPLE DIAGNOSTIC - Works with Old Schema
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Check if citizendemo has OneSignal registered
SELECT 
  u.email,
  u.raw_user_meta_data->>'role' as role,
  CASE 
    WHEN os.player_id IS NOT NULL THEN '✅ HAS PLAYER ID'
    ELSE '❌ NO PLAYER ID - OPEN APP NOW'
  END as status,
  os.player_id,
  os.updated_at
FROM auth.users u
LEFT JOIN onesignal_subscriptions os ON u.id = os.user_id
WHERE u.email LIKE '%demo%' OR u.email LIKE '%citizen%'
ORDER BY u.email;

-- ============================================

-- 2. Check ALL OneSignal registrations
SELECT 
  u.email,
  u.raw_user_meta_data->>'role' as role,
  os.player_id,
  os.updated_at
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
ORDER BY os.updated_at DESC;

-- ============================================

-- 3. Check recent announcements
SELECT 
  id,
  title,
  type,
  priority,
  target_audience,
  created_at,
  status
FROM announcements
ORDER BY created_at DESC
LIMIT 5;

-- ============================================

-- 4. Check notifications sent to citizendemo (OLD SCHEMA with user_id)
SELECT 
  n.type,
  n.title,
  n.message,
  n.created_at,
  n.read as is_read,
  u.email
FROM notifications n
JOIN auth.users u ON n.user_id = u.id
WHERE u.email LIKE '%demo%' OR u.email LIKE '%citizen%'
ORDER BY n.created_at DESC
LIMIT 10;

-- ============================================
-- IF QUERY 4 FAILS, USE THIS INSTEAD (NEW SCHEMA with target_id):
-- ============================================
/*
SELECT 
  n.type,
  n.title,
  n.message,
  n.created_at,
  n.is_read,
  u.email
FROM notifications n
JOIN auth.users u ON n.target_id = u.id
WHERE u.email LIKE '%demo%' OR u.email LIKE '%citizen%'
ORDER BY n.created_at DESC
LIMIT 10;
*/

-- ============================================
-- ✅ WHAT TO LOOK FOR:
-- ============================================
-- Query 1: citizendemo should have "✅ HAS PLAYER ID"
--          If "❌ NO PLAYER ID" → Open the mobile app NOW
-- 
-- Query 2: Should show multiple users registered
--
-- Query 3: Should show recent announcements you created
--
-- Query 4: Should show notifications sent to citizendemo
--          (If this query fails, uncomment the one above it)
-- ============================================

