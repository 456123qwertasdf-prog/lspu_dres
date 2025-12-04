-- ============================================================================
-- Test Mobile App Notification System
-- ============================================================================
-- This script helps you test if mobile super users can send notifications
-- to responders when assigning reports.
--
-- Run these queries in Supabase SQL Editor to verify the system works.
-- ============================================================================

-- ============================================================================
-- STEP 1: Check which responders can receive notifications
-- ============================================================================
-- This shows which responders have registered devices and can receive push notifications

SELECT 
  r.id as responder_id,
  r.name as responder_name,
  r.user_id,
  u.email,
  r.is_available,
  r.status,
  os.player_id as onesignal_player_id,
  os.created_at as device_registered_at,
  CASE 
    WHEN os.player_id IS NOT NULL THEN '✅ Can receive notifications'
    ELSE '❌ Needs to log into mobile app'
  END as notification_status
FROM responder r
JOIN auth.users u ON u.id = r.user_id
LEFT JOIN onesignal_subscriptions os ON os.user_id = r.user_id
WHERE u.deleted_at IS NULL
ORDER BY r.name;

-- Expected: See list of responders with their OneSignal player IDs
-- If player_id is NULL, that responder needs to log into the mobile app first


-- ============================================================================
-- STEP 2: Check recent assignments (to verify new ones are created)
-- ============================================================================
-- This shows the most recent assignments with responder and report details

SELECT 
  a.id as assignment_id,
  a.report_id,
  a.responder_id,
  r.name as responder_name,
  rep.type as report_type,
  rep.priority,
  rep.severity,
  a.status as assignment_status,
  a.assigned_at,
  a.created_at,
  CASE 
    WHEN a.assigned_at > NOW() - INTERVAL '5 minutes' THEN '🆕 NEW'
    WHEN a.assigned_at > NOW() - INTERVAL '1 hour' THEN '⏰ Recent'
    ELSE '📅 Older'
  END as age
FROM assignment a
JOIN responder r ON r.id = a.responder_id
JOIN reports rep ON rep.id = a.report_id
ORDER BY a.assigned_at DESC
LIMIT 20;

-- Expected: See recent assignments
-- After testing mobile app, you should see a NEW assignment appear


-- ============================================================================
-- STEP 3: Check notifications sent to responders
-- ============================================================================
-- This shows notifications that were created when responders were assigned

SELECT 
  n.id as notification_id,
  n.target_id as user_id,
  u.email,
  r.name as responder_name,
  n.type,
  n.title,
  n.message,
  n.payload->>'assignment_id' as assignment_id,
  n.payload->>'report_type' as report_type,
  n.payload->>'priority' as priority,
  n.payload->>'is_critical' as is_critical,
  n.is_read,
  n.created_at,
  CASE 
    WHEN n.created_at > NOW() - INTERVAL '5 minutes' THEN '🆕 NEW'
    WHEN n.created_at > NOW() - INTERVAL '1 hour' THEN '⏰ Recent'
    ELSE '📅 Older'
  END as age
FROM notifications n
JOIN auth.users u ON u.id = n.target_id
LEFT JOIN responder r ON r.user_id = n.target_id
WHERE n.type = 'assignment_created'
  AND n.target_type = 'responder'
ORDER BY n.created_at DESC
LIMIT 20;

-- Expected: See notifications created for responders
-- After testing mobile app, you should see a NEW notification appear


-- ============================================================================
-- STEP 4: Get unassigned reports for testing
-- ============================================================================
-- This shows reports that are available for assignment testing

SELECT 
  r.id,
  r.type,
  r.priority,
  r.severity,
  r.status,
  r.lifecycle_status,
  r.message,
  r.reporter_name,
  r.location,
  r.created_at,
  CASE 
    WHEN r.priority <= 2 OR r.severity IN ('CRITICAL', 'HIGH') THEN '🔴 CRITICAL/HIGH'
    ELSE '🟠 NORMAL'
  END as notification_priority
FROM reports r
WHERE r.responder_id IS NULL
  AND r.lifecycle_status NOT IN ('resolved', 'closed')
ORDER BY r.created_at DESC
LIMIT 10;

-- Expected: See unassigned reports
-- Use one of these report IDs to test assignment from mobile app


-- ============================================================================
-- STEP 5: Verify Edge Functions are working (check logs)
-- ============================================================================
-- You can't query Edge Function logs from SQL, but here are the URLs:

-- assign-responder logs:
-- https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/functions/assign-responder/logs

-- notify-responder-assignment logs:
-- https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/functions/notify-responder-assignment/logs


-- ============================================================================
-- STEP 6: Check super users who can assign responders
-- ============================================================================
-- This shows which super users can assign responders from mobile app

SELECT 
  u.id as user_id,
  u.email,
  u.role,
  os.player_id as onesignal_player_id,
  os.created_at as device_registered_at,
  CASE 
    WHEN os.player_id IS NOT NULL THEN '✅ Logged into mobile app'
    ELSE '❌ Not logged into mobile app'
  END as mobile_status
FROM auth.users u
LEFT JOIN onesignal_subscriptions os ON os.user_id = u.id
WHERE u.role IN ('super_user', 'admin')
  AND u.deleted_at IS NULL
ORDER BY u.email;

-- Expected: See super users with their mobile app status


-- ============================================================================
-- STEP 7: Detailed view of a specific assignment (use after testing)
-- ============================================================================
-- Replace 'ASSIGNMENT_ID_HERE' with an actual assignment ID from Step 2

-- SELECT 
--   a.*,
--   r.name as responder_name,
--   r.phone as responder_phone,
--   rep.type as report_type,
--   rep.priority,
--   rep.severity,
--   rep.message as report_message,
--   rep.location,
--   n.id as notification_id,
--   n.title as notification_title,
--   n.message as notification_message,
--   n.is_read as notification_read,
--   n.created_at as notification_sent_at
-- FROM assignment a
-- JOIN responder r ON r.id = a.responder_id
-- JOIN reports rep ON rep.id = a.report_id
-- LEFT JOIN notifications n ON n.payload->>'assignment_id' = a.id::text
-- WHERE a.id = 'ASSIGNMENT_ID_HERE';


-- ============================================================================
-- TESTING CHECKLIST
-- ============================================================================
-- 
-- Before Testing:
-- [ ] Run Step 1 - Verify responders have OneSignal player IDs
-- [ ] Run Step 4 - Get an unassigned report ID
-- [ ] Run Step 6 - Verify super user is logged into mobile app
-- 
-- During Testing:
-- [ ] Open mobile app as super user
-- [ ] Go to Reports tab
-- [ ] Select an unassigned report
-- [ ] Tap Edit button
-- [ ] Select a responder from dropdown
-- [ ] Tap Save Changes
-- [ ] Check responder's mobile device for push notification
-- 
-- After Testing:
-- [ ] Run Step 2 - Verify new assignment was created
-- [ ] Run Step 3 - Verify notification was created
-- [ ] Check assign-responder Edge Function logs
-- [ ] Check notify-responder-assignment Edge Function logs
-- [ ] Verify responder received push notification on device
-- [ ] Verify responder sees notification in app
-- 
-- ============================================================================


-- ============================================================================
-- TROUBLESHOOTING QUERIES
-- ============================================================================

-- If responder didn't receive notification, check if they have a device:
-- SELECT * FROM onesignal_subscriptions 
-- WHERE user_id = (SELECT user_id FROM responder WHERE name = 'RESPONDER_NAME_HERE');

-- Check if assignment was created:
-- SELECT * FROM assignment 
-- WHERE report_id = 'REPORT_ID_HERE' 
-- ORDER BY created_at DESC LIMIT 1;

-- Check if notification was created:
-- SELECT * FROM notifications 
-- WHERE payload->>'report_id' = 'REPORT_ID_HERE'
-- ORDER BY created_at DESC LIMIT 1;

-- ============================================================================

