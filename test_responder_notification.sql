-- ============================================
-- TEST RESPONDER ASSIGNMENT NOTIFICATION
-- ============================================

-- Step 1: Find responders with OneSignal IDs
SELECT 
  r.id as responder_id,
  r.name as responder_name,
  r.user_id,
  u.email,
  os.player_id as onesignal_player_id,
  os.created_at as device_registered_at
FROM responder r
JOIN auth.users u ON u.id = r.user_id
LEFT JOIN onesignal_subscriptions os ON os.user_id = r.user_id
WHERE u.deleted_at IS NULL
  AND os.player_id IS NOT NULL
ORDER BY r.name;

-- Step 2: Find an unassigned report or create test assignment
SELECT 
  id as report_id,
  type,
  priority,
  severity,
  message,
  created_at
FROM reports
WHERE assignment_id IS NULL
  OR responder_id IS NULL
ORDER BY created_at DESC
LIMIT 5;

-- Step 3: Create a test assignment (MANUALLY via Super User Dashboard)
-- OR use curl to test the Edge Function directly:

/*
-- Get a report_id from Step 2
-- Get a responder_id from Step 1
-- Then run this curl command:

curl -X POST 'https://hmolyqzbvxxliemclrld.supabase.co/functions/v1/assign-responder' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_SERVICE_ROLE_KEY' \
  -d '{
    "report_id": "YOUR_REPORT_ID",
    "responder_id": "YOUR_RESPONDER_ID",
    "assigned_by": "YOUR_USER_ID"
  }'
*/

-- Step 4: Verify notification was created in database
SELECT 
  n.id,
  n.type,
  n.title,
  n.message,
  n.created_at,
  n.target_type,
  n.target_id,
  u.email,
  n.is_read
FROM notifications n
LEFT JOIN auth.users u ON u.id = n.target_id
WHERE n.type = 'assignment_created'
ORDER BY n.created_at DESC
LIMIT 10;

-- Step 5: Check Edge Function logs
-- Go to: https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/functions/notify-responder-assignment/logs
-- Look for: "✅ Push notification sent to responder"

