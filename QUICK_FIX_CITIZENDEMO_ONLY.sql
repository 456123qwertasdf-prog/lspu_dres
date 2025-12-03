-- ============================================
-- QUICK FIX: Keep only citizen@demo.com
-- ============================================
-- Delete registrations for the other accounts
-- Keep citizendemo intact so you can test immediately

-- STEP 1: Delete ONLY responder and superuser
-- Keep citizen@demo.com
DELETE FROM onesignal_subscriptions
WHERE user_id IN (
  SELECT u.id 
  FROM auth.users u
  WHERE u.email IN ('responder@demo.com', 'superuser@lspu-dres.com')
);

-- STEP 2: Verify only citizen@demo.com remains
SELECT 
  '✅ Only citizendemo remains' as status,
  u.email,
  u.raw_user_meta_data->>'role' as role,
  os.player_id,
  os.created_at
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id;

-- ============================================
-- EXPECTED RESULT:
-- ============================================
-- Should show only 1 row:
-- email: citizen@demo.com
-- role: citizen
-- player_id: 9977822c-7c52-4799-9451-1c06de7c635b
--
-- ============================================
-- AFTER RUNNING THIS - TEST IMMEDIATELY:
-- ============================================
--
-- 1. MOBILE: Make sure logged in as citizen@demo.com
-- 2. MOBILE: Press Home button (keep app in background)
-- 3. WEB: Login as superuser@lspu-dres.com
-- 4. WEB: Create announcement:
--    - Type: Emergency
--    - Target: All (or Citizens)
--    - Title: "Test Alert from Web"
--    - Message: "Testing notifications with app closed"
-- 5. WEB: Click Send
-- 6. MOBILE: Should receive notification! 📱🎉
--
-- If notification arrives = BUG IS FIXED! ✅
--
-- ============================================

