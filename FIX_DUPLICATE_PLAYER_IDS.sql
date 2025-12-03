-- ============================================
-- FIX: Remove duplicate player_ids
-- ============================================
-- This will clean up the duplicate player_id issue
-- Run this, then reinstall the mobile app

-- STEP 1: Delete ALL OneSignal subscriptions
-- (This forces a clean reset)
DELETE FROM onesignal_subscriptions;

-- STEP 2: Also clean up the old users table player_id column if it exists
UPDATE users 
SET onesignal_player_id = NULL 
WHERE onesignal_player_id IS NOT NULL;

-- STEP 3: Verify everything is clean
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
-- ⚠️ IMPORTANT: Test Different Accounts on Different Devices
-- ============================================
--
-- If you need to test multiple accounts:
-- - citizen@demo.com → Test on Device A (or emulator 1)
-- - responder@demo.com → Test on Device B (or emulator 2)
-- - superuser@lspu-dres.com → Test on Device C (or emulator 3)
--
-- Each device will get its own unique player_id
-- This prevents conflicts
--
-- ============================================

