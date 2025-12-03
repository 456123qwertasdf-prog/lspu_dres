-- ============================================
-- QUICK FIX: Keep only citizen@demo.com registration
-- ============================================
-- This removes the other two accounts' registrations
-- Keeps citizendemo intact

-- STEP 1: Find citizendemo's user_id
-- (Should be: 22d7f4a7-f8da-4504-8126-b6b08d1b3cd7 based on your results)

-- STEP 2: Delete registrations for responder and superuser
-- Keep only citizen@demo.com
DELETE FROM onesignal_subscriptions
WHERE user_id IN (
  SELECT u.id 
  FROM auth.users u
  WHERE u.email IN ('responder@demo.com', 'superuser@lspu-dres.com')
);

-- STEP 3: Verify only citizen@demo.com remains
SELECT 
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
-- AFTER RUNNING THIS:
-- ============================================
--
-- 1. MOBILE APP: Make sure you're logged in as citizen@demo.com
-- 2. MOBILE APP: Close the app (press Home button)
-- 3. WEB: Login as superuser
-- 4. WEB: Create an announcement:
--    - Type: Emergency
--    - Target: All (or Citizens)
--    - Title: "Test Notification"
--    - Message: "Testing closed app notifications"
-- 5. MOBILE: Should receive notification! 🎉
--
-- ⚠️ NOTE: responder and superuser won't receive notifications
-- until they open the app again to re-register
--
-- ============================================

