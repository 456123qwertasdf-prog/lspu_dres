-- Enable pg_cron extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Enable pg_net extension for HTTP requests
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Schedule weather cache update every 2 hours
-- This keeps AccuWeather API usage to 12 calls/day (well within 50 limit)
SELECT cron.schedule(
  'update-weather-cache-every-2hrs',
  '0 */2 * * *',  -- At minute 0 of every 2nd hour (12:00 AM, 2:00 AM, 4:00 AM, etc.)
  $$
  SELECT
    net.http_post(
      url := 'https://hmolyqzbvxxliemclrld.supabase.co/functions/v1/update-weather-cache',
      headers := jsonb_build_object(
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhtb2x5cXpidnh4bGllbWNscmxkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDI0Njk3MCwiZXhwIjoyMDc1ODIyOTcwfQ.496txRbAGuiOov76vxdwSDUHplBt1osOD2PyV0EE958',
        'Content-Type', 'application/json'
      ),
      body := '{"location": "LSPU"}'::jsonb
    ) AS request_id;
  $$
);

-- Verify the cron job was created
SELECT * FROM cron.job WHERE jobname = 'update-weather-cache-every-2hrs';

-- To manually unscheduled (if needed later):
-- SELECT cron.unschedule('update-weather-cache-every-2hrs');

-- To manually trigger update (for testing):
-- SELECT net.http_post(
--   url := 'https://hmolyqzbvxxliemclrld.supabase.co/functions/v1/update-weather-cache',
--   headers := jsonb_build_object(
--     'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhtb2x5cXpidnh4bGllbWNscmxkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDI0Njk3MCwiZXhwIjoyMDc1ODIyOTcwfQ.496txRbAGuiOov76vxdwSDUHplBt1osOD2PyV0EE958',
--     'Content-Type', 'application/json'
--   ),
--   body := '{"location": "LSPU"}'::jsonb
-- );

