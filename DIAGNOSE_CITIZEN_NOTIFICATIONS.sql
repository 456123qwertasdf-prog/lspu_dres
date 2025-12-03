-- ============================================
-- DIAGNOSE: Why citizendemo is not receiving notifications
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Check if citizendemo account exists and has OneSignal registered
SELECT 
  '1️⃣ citizendemo Account Status' as check_name,
  u.email,
  u.raw_user_meta_data->>'role' as role,
  u.created_at as account_created,
  CASE 
    WHEN os.player_id IS NOT NULL THEN '✅ OneSignal Player ID Registered'
    ELSE '❌ NO OneSignal Player ID - USER NEEDS TO OPEN APP'
  END as onesignal_status,
  os.player_id,
  os.updated_at as last_onesignal_update
FROM auth.users u
LEFT JOIN onesignal_subscriptions os ON u.id = os.user_id
WHERE u.email LIKE '%demo%' OR u.email LIKE '%citizen%'
ORDER BY u.email;

-- ============================================

-- 2. Check ALL users with OneSignal subscriptions
SELECT 
  '2️⃣ All Users with OneSignal' as check_name,
  u.email,
  u.raw_user_meta_data->>'role' as role,
  os.player_id,
  os.platform,
  os.updated_at as registered_at
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
ORDER BY os.updated_at DESC;

-- ============================================

-- 3. Check if citizendemo has player_id in USERS table (old format)
SELECT 
  '3️⃣ citizendemo in USERS table' as check_name,
  u.email,
  u.raw_user_meta_data->>'role' as role,
  u.onesignal_player_id,
  u.updated_at
FROM users u
JOIN auth.users au ON u.id = au.id
WHERE au.email LIKE '%demo%' OR au.email LIKE '%citizen%';

-- ============================================

-- 4. Summary Stats
SELECT 
  '4️⃣ Summary' as check_name,
  COUNT(DISTINCT u.id) as total_users,
  COUNT(DISTINCT os.user_id) as users_with_onesignal,
  COUNT(DISTINCT CASE WHEN u.raw_user_meta_data->>'role' = 'citizen' THEN u.id END) as total_citizens,
  COUNT(DISTINCT CASE WHEN u.raw_user_meta_data->>'role' = 'citizen' AND os.user_id IS NOT NULL THEN u.id END) as citizens_with_onesignal
FROM auth.users u
LEFT JOIN onesignal_subscriptions os ON u.id = os.user_id
WHERE u.raw_user_meta_data->>'role' IS NOT NULL;

-- ============================================

-- 5. Check recent announcements/alerts
SELECT 
  '5️⃣ Recent Announcements' as check_name,
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

-- 6. Check if notifications were sent to citizendemo
-- This query handles both old (user_id) and new (target_id) schema
SELECT 
  '6️⃣ Notifications to citizendemo' as check_name,
  n.type,
  n.title,
  n.message,
  n.created_at,
  COALESCE(n.read, n.is_read) as is_read,
  u.email as sent_to
FROM notifications n
JOIN auth.users u ON (
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'notifications' 
                 AND column_name = 'user_id') 
    THEN n.user_id = u.id
    ELSE n.target_id = u.id
  END
)
WHERE u.email LIKE '%demo%' OR u.email LIKE '%citizen%'
ORDER BY n.created_at DESC
LIMIT 10;

-- ============================================
-- ✅ EXPECTED RESULTS
-- ============================================
-- 
-- Check 1: Should show citizendemo with OneSignal Player ID
-- Check 2: Should show all users who opened the app
-- Check 3: Should show citizendemo in users table with player_id
-- Check 4: Should show at least 1 citizen with OneSignal
-- Check 5: Should show recent announcements created by super_user
-- Check 6: Should show notifications sent to citizendemo
--
-- ============================================
-- 🚨 IF NO PLAYER ID FOUND FOR CITIZENDEMO
-- ============================================
--
-- The user needs to:
-- 1. Open the mobile app
-- 2. Stay logged in as citizendemo
-- 3. Wait 5-10 seconds for OneSignal to initialize
-- 4. Check app logs for "✅ OneSignal Player ID saved"
-- 5. Run this query again to confirm
--
-- ============================================

