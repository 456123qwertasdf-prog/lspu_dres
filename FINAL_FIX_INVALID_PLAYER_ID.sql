-- ============================================
-- FINAL FIX: Remove Invalid Player ID
-- ============================================
-- The player_id in the database is invalid in OneSignal
-- We need to delete it so the app can register a fresh one

-- STEP 1: Delete the invalid player_id
DELETE FROM onesignal_subscriptions 
WHERE player_id = '9977822c-7c52-4799-9451-1c06de7c635b';

-- STEP 2: Verify database is now empty
SELECT 
  'Database cleaned - ready for fresh registration' as status,
  COUNT(*) as remaining_subscriptions
FROM onesignal_subscriptions;

-- ============================================
-- AFTER RUNNING THIS - REGISTER NEW PLAYER ID:
-- ============================================
--
-- 1. MOBILE APP: Open the app
-- 2. MOBILE APP: Login as citizen@demo.com
-- 3. MOBILE APP: Wait 15 seconds (let OneSignal register)
-- 4. MOBILE APP: Check logs for:
--    "✅ OneSignal Player ID saved to Supabase: <NEW_ID>"
-- 5. The NEW player_id will be different from the old one
--
-- ============================================
-- THEN VERIFY NEW REGISTRATION:
-- ============================================
--
-- Run this query to see the new player_id:
/*
SELECT 
  u.email,
  os.player_id as new_player_id,
  os.created_at as registered_at,
  'This should be a NEW player_id!' as note
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
WHERE u.email = 'citizen@demo.com';
*/
--
-- ============================================
-- FINALLY, TEST NOTIFICATION:
-- ============================================
--
-- 1. MOBILE: Press Home button (app in background)
-- 2. WEB: Login as superuser
-- 3. WEB: Create "Fire Emergency Alert" again
-- 4. MOBILE: Should receive notification! 📱🎉
--
-- If you receive the notification = BUG IS FIXED! ✅
--
-- ============================================

