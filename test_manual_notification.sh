#!/bin/bash
# Test the notification function manually with a recent critical report

# Get the most recent critical report ID (replace with actual ID from your query)
REPORT_ID="YOUR_REPORT_ID_HERE"  # Use one from the medical reports you saw earlier

# Call the notification function
curl -X POST 'https://hmolyqzbvxxliemclrld.supabase.co/functions/v1/notify-superusers-critical-report' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhtb2x5cXpidnh4bGllbWNscmxkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDI0Njk3MCwiZXhwIjoyMDc1ODIyOTcwfQ.496txRbAGuiOov76vxdwSDUHplBt1osOD2PyV0EE958' \
  -d "{\"report_id\": \"$REPORT_ID\"}"

