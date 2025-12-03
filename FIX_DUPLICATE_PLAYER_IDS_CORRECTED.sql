-- ============================================
-- FIX: Remove duplicate player_ids (CORRECTED)
-- ============================================
-- This will clean up the duplicate player_id issue
-- Skips the users view update (not needed)

-- STEP 1: Delete ALL OneSignal subscriptions
-- (This is the main table that matters for notifications)
DELETE FROM onesignal_subscriptions;

-- STEP 2: Verify everything is clean
SELECT 
  'All OneSignal subscriptions deleted' as status,
  COUNT(*) as remaining_subscriptions
FROM onesignal_subscriptions;

-- ============================================
-- AFTER RUNNING THIS:
-- ============================================
-- 
-- 1. MOBILE APP: Uninstall the app completely
-- 2. MOBILE APP: Reinstall the app from scratch
-- 3. MOBILE APP: Login ONLY as citizen@demo.com
-- 4. MOBILE APP: Wait 10 seconds (let OneSignal initialize)
-- 5. MOBILE APP: Check logs for "✅ OneSignal Player ID saved"
-- 6. RUN DIAGNOSTIC: Run IDENTIFY_CITIZENDEMO_PLAYER_ID.sql again
-- 7. VERIFY: Should now show only 1 user with a UNIQUE player_id
-- 8. TEST: Close app → Create announcement → Should receive notification!
--
-- ============================================

