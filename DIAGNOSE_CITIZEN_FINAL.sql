-- ============================================
-- FINAL DIAGNOSTIC - Works with NEW Schema (target_id)
-- Run this in Supabase SQL Editor
-- ============================================

-- 1️⃣ Check if citizendemo has OneSignal Player ID
SELECT 
  '1️⃣ citizendemo OneSignal Status' as check_name,
  u.email,
  u.raw_user_meta_data->>'role' as role,
  CASE 
    WHEN os.player_id IS NOT NULL THEN '✅ HAS PLAYER ID - READY FOR NOTIFICATIONS'
    ELSE '❌ NO PLAYER ID - MUST OPEN APP NOW!'
  END as status,
  os.player_id,
  os.updated_at as registered_at
FROM auth.users u
LEFT JOIN onesignal_subscriptions os ON u.id = os.user_id
WHERE u.email LIKE '%demo%' OR u.email LIKE '%citizen%'
ORDER BY u.email;

-- ============================================

-- 2️⃣ Check ALL users with OneSignal registered
SELECT 
  '2️⃣ All OneSignal Registrations' as check_name,
  u.email,
  u.raw_user_meta_data->>'role' as role,
  os.player_id,
  os.platform,
  os.updated_at as registered_at
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
ORDER BY os.updated_at DESC;

-- ============================================

-- 3️⃣ Check recent announcements
SELECT 
  '3️⃣ Recent Announcements' as check_name,
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

-- 4️⃣ Check notifications sent to citizendemo (NEW SCHEMA - target_id)
SELECT 
  '4️⃣ Notifications to citizendemo' as check_name,
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

-- ============================================

-- 5️⃣ Summary Stats
SELECT 
  '5️⃣ Summary' as check_name,
  COUNT(DISTINCT u.id) as total_users,
  COUNT(DISTINCT os.user_id) as users_with_onesignal,
  COUNT(DISTINCT CASE WHEN u.raw_user_meta_data->>'role' = 'citizen' THEN u.id END) as total_citizens,
  COUNT(DISTINCT CASE WHEN u.raw_user_meta_data->>'role' = 'citizen' AND os.user_id IS NOT NULL THEN u.id END) as citizens_with_onesignal
FROM auth.users u
LEFT JOIN onesignal_subscriptions os ON u.id = os.user_id
WHERE u.raw_user_meta_data->>'role' IS NOT NULL;

-- ============================================
-- ✅ WHAT THE RESULTS MEAN:
-- ============================================
--
-- 1️⃣ citizendemo Status:
--    ✅ "HAS PLAYER ID" = Good! Ready for notifications
--    ❌ "NO PLAYER ID" = STOP! Open mobile app right now!
--
-- 2️⃣ All Registrations:
--    Shows who has opened the app and registered
--
-- 3️⃣ Recent Announcements:
--    Shows announcements created (should see your test announcements)
--
-- 4️⃣ Notifications:
--    Shows if notifications were created in database
--    (Push notifications happen separately via OneSignal)
--
-- 5️⃣ Summary:
--    Quick overview of how many users are registered
--
-- ============================================
-- 🚨 IF CITIZENDEMO HAS NO PLAYER ID:
-- ============================================
--
-- YOU MUST DO THIS FIRST:
-- 1. Open mobile app
-- 2. Login as citizendemo
-- 3. Wait 10 seconds (let OneSignal initialize)
-- 4. Check app logs for: "✅ OneSignal Player ID saved"
-- 5. Run this query again
-- 6. Should now show "✅ HAS PLAYER ID"
--
-- ============================================
-- 📱 THEN TEST ANNOUNCEMENT:
-- ============================================
--
-- MOBILE (citizendemo):
-- - Press Home button (keep app in background, stay logged in)
-- - Lock the screen
--
-- WEB (super_user):
-- - Create announcement:
--   • Type: Emergency
--   • Target: All (or Citizens)
--   • Title: "Test Alert"
--   • Message: "Testing notifications"
-- - Send
--
-- EXPECTED:
-- - Mobile device receives notification 📱
-- - Even though app is closed/locked
--
-- ============================================

