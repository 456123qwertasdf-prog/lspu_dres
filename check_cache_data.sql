-- Check what forecast data is in the cache
SELECT 
  location_name,
  data_source,
  hourly_forecast,
  daily_forecast,
  last_updated
FROM weather_cache
WHERE latitude = 14.262585 AND longitude = 121.398436;

