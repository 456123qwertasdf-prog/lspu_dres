-- Test the hybrid weather strategy
-- This will fetch current from AccuWeather and forecast from WeatherAPI

SELECT net.http_post(
  url := 'https://hmolyqzbvxxliemclrld.supabase.co/functions/v1/update-weather-cache',
  headers := jsonb_build_object(
    'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhtb2x5cXpidnh4bGllbWNscmxkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDI0Njk3MCwiZXhwIjoyMDc1ODIyOTcwfQ.496txRbAGuiOov76vxdwSDUHplBt1osOD2PyV0EE958',
    'Content-Type', 'application/json'
  ),
  body := '{"location": "LSPU"}'::jsonb
);

-- After running above, check the results:
-- SELECT 
--   location_name,
--   temperature,
--   data_source,
--   hourly_forecast IS NOT NULL as has_hourly,
--   daily_forecast IS NOT NULL as has_daily,
--   air_quality_index IS NOT NULL as has_aqi,
--   last_updated
-- FROM weather_cache;

