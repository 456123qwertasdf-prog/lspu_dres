-- Weather cache table for storing fetched weather data
CREATE TABLE weather_cache (
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
CREATE TABLE weather_api_usage (
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
CREATE INDEX idx_weather_cache_location ON weather_cache(latitude, longitude);
CREATE INDEX idx_weather_api_usage_date ON weather_api_usage(created_at);
CREATE INDEX idx_weather_api_usage_provider ON weather_api_usage(api_provider, created_at);

-- Insert LSPU location
INSERT INTO weather_cache (location_name, latitude, longitude, data_source, cache_expires_at)
VALUES ('LSPU Santa Cruz Main Campus', 14.262585, 121.398436, 'accuweather', NOW());

-- Enable RLS
ALTER TABLE weather_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather_api_usage ENABLE ROW LEVEL SECURITY;

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

