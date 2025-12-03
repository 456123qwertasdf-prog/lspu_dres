-- Check if weather tables exist and have data

-- 1. Check if weather_cache table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_name = 'weather_cache'
) as weather_cache_exists;

-- 2. Check if weather_api_usage table exists  
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_name = 'weather_api_usage'
) as weather_api_usage_exists;

-- 3. Check weather cache data
SELECT 
  location_name,
  latitude,
  longitude,
  temperature,
  data_source,
  hourly_forecast IS NOT NULL as has_hourly,
  daily_forecast IS NOT NULL as has_daily,
  last_updated,
  AGE(NOW(), last_updated) as cache_age
FROM weather_cache;

-- 4. Check API usage today
SELECT 
  api_provider,
  COUNT(*) as calls,
  SUM(calls_count) as total_api_calls
FROM weather_api_usage
WHERE created_at >= CURRENT_DATE
GROUP BY api_provider;

-- 5. Check cron job
SELECT * FROM cron.job WHERE jobname = 'update-weather-cache-every-2hrs';

