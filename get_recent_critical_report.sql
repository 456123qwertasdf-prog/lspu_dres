-- Get the most recent critical/high priority report ID for testing
SELECT 
  id,
  type,
  priority,
  severity,
  created_at,
  response_time
FROM reports
WHERE (priority <= 2 OR severity IN ('CRITICAL', 'HIGH'))
  AND created_at > NOW() - INTERVAL '1 day'
ORDER BY created_at DESC
LIMIT 1;

-- Copy the 'id' from the result and use it to test the notification function
-- Go to: https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/functions/notify-superusers-critical-report/
-- Click "Test" button
-- Paste this JSON (replace YOUR_REPORT_ID with the id from above):
-- {"report_id": "YOUR_REPORT_ID"}

