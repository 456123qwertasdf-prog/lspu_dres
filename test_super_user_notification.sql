-- ============================================
-- TEST SUPER USER NOTIFICATION MANUALLY
-- This will help you test if the notification system works
-- ============================================

-- Step 1: Find a recent report (or any report)
SELECT 
  id,
  type,
  priority,
  severity,
  created_at
FROM reports
ORDER BY created_at DESC
LIMIT 5;

-- Step 2: Update a report to be CRITICAL (replace 'YOUR_REPORT_ID' with actual report ID)
-- Example: UPDATE reports SET priority = 1, severity = 'CRITICAL' WHERE id = 'your-report-id-here';

UPDATE reports 
SET 
  priority = 1, 
  severity = 'CRITICAL',
  response_time = '5 minutes'
WHERE id = (SELECT id FROM reports ORDER BY created_at DESC LIMIT 1);

-- Step 3: Now manually test the Edge Function
-- Copy the report ID from Step 1 and use it below
-- You can test this via curl or Postman:

/*
curl -X POST 'https://hmolyqzbvxxliemclrld.supabase.co/functions/v1/notify-superusers-critical-report' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_SERVICE_ROLE_KEY' \
  -d '{"report_id": "YOUR_REPORT_ID"}'
*/

-- Or test via Supabase Dashboard > Edge Functions > notify-superusers-critical-report > Test

