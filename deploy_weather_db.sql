-- Deploy Weather Cache System Database Changes
-- Run this in Supabase SQL Editor

-- Weather cache table for storing fetched weather data
CREATE TABLE IF NOT EXISTS weather_cache (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  location_name TEXT NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  
  -- Current weather data
  temperature DECIMAL(5, 2),
  feels_like DECIMAL(5, 2),
  weather_text TEXT,
  weather_icon TEXT,
  humidity INTEGER,
  wind_speed DECIMAL(5, 2),
  wind_direction INTEGER,
  pressure DECIMAL(6, 2),
  visibility DECIMAL(6, 2),
  cloud_cover INTEGER,
  uv_index DECIMAL(3, 1),
  
  -- Air quality data (from WeatherAPI fallback)
  air_quality_index INTEGER,
  pm2_5 DECIMAL(6, 2),
  pm10 DECIMAL(6, 2),
  
  -- Precipitation data
  rain_1h DECIMAL(5, 2),
  rain_probability INTEGER,
  
  -- Forecast data (JSON)
  hourly_forecast JSONB,
  daily_forecast JSONB,
  weather_alerts JSONB,
  
  -- Metadata
  data_source TEXT NOT NULL DEFAULT 'accuweather', -- 'accuweather' or 'weatherapi'
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  cache_expires_at TIMESTAMPTZ,
  
  UNIQUE(latitude, longitude)
);

-- API usage tracking table
CREATE TABLE IF NOT EXISTS weather_api_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  api_provider TEXT NOT NULL,
  endpoint TEXT,
  calls_count INTEGER DEFAULT 1,
  success BOOLEAN DEFAULT true,
  error_message TEXT,
  response_time_ms INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_weather_cache_location ON weather_cache(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_weather_api_usage_date ON weather_api_usage(created_at);
CREATE INDEX IF NOT EXISTS idx_weather_api_usage_provider ON weather_api_usage(api_provider, created_at);

-- Insert LSPU location
INSERT INTO weather_cache (location_name, latitude, longitude, data_source, cache_expires_at)
VALUES ('LSPU Santa Cruz Main Campus', 14.262585, 121.398436, 'accuweather', NOW())
ON CONFLICT (latitude, longitude) DO NOTHING;

-- Enable RLS
ALTER TABLE weather_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather_api_usage ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public read access to weather cache" ON weather_cache;
DROP POLICY IF EXISTS "Allow service role to manage weather cache" ON weather_cache;
DROP POLICY IF EXISTS "Allow service role to manage API usage" ON weather_api_usage;

-- Allow all users to read weather cache
CREATE POLICY "Allow public read access to weather cache"
  ON weather_cache FOR SELECT
  TO public
  USING (true);

-- Only service role can write
CREATE POLICY "Allow service role to manage weather cache"
  ON weather_cache FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow service role to manage API usage"
  ON weather_api_usage FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Enable pg_cron extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Enable pg_net extension for HTTP requests
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Unschedule existing job if it exists (ignore error if it doesn't exist)
DO $$
BEGIN
    PERFORM cron.unschedule('update-weather-cache-every-2hrs');
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Ignore error if job doesn't exist
END $$;

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

