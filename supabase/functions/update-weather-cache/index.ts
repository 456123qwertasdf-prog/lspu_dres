import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { fetchAccuWeatherData } from "../_shared/accuweather.ts";
import { fetchWeatherAPIData } from "../_shared/weatherapi.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "https://hmolyqzbvxxliemclrld.supabase.co";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

const supabase = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { persistSession: false },
});

// LSPU coordinates
const LSPU_LATITUDE = 14.262585;
const LSPU_LONGITUDE = 121.398436;
const LSPU_LOCATION_NAME = "LSPU Santa Cruz Main Campus";

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface WeatherCacheUpdate {
  location_name: string;
  latitude: number;
  longitude: number;
  temperature: number;
  feels_like: number;
  weather_text: string;
  weather_icon: string;
  humidity: number;
  wind_speed: number;
  wind_direction: number;
  pressure: number;
  visibility: number;
  cloud_cover: number;
  uv_index: number;
  rain_1h: number;
  rain_probability: number | null;
  air_quality_index: number | null;
  pm2_5: number | null;
  pm10: number | null;
  hourly_forecast: any;
  daily_forecast: any;
  weather_alerts: any;
  data_source: string;
  last_updated: string;
  cache_expires_at: string;
}

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    console.log("🌤️ Starting weather cache update...");

    // Check AccuWeather API usage for today
    const today = new Date().toISOString().split('T')[0];
    const { data: usageToday, error: usageError } = await supabase
      .from('weather_api_usage')
      .select('calls_count')
      .eq('api_provider', 'accuweather')
      .gte('created_at', `${today}T00:00:00Z`);

    if (usageError) {
      console.warn("⚠️ Could not fetch API usage data:", usageError);
    }

    const totalAccuWeatherCalls = usageToday?.reduce((sum, record) => sum + record.calls_count, 0) || 0;
    console.log(`📊 AccuWeather calls today: ${totalAccuWeatherCalls}/50`);

    let weatherData;
    let dataSource;
    let responseTime;
    let apiSuccess = true;
    let errorMessage = null;

    // Try AccuWeather first if we haven't reached the daily limit
    if (totalAccuWeatherCalls < 45) { // Buffer of 5 calls
      console.log("🌟 Attempting to fetch from AccuWeather (primary)...");
      try {
        const result = await fetchAccuWeatherData(LSPU_LATITUDE, LSPU_LONGITUDE);
        weatherData = result.data;
        responseTime = result.responseTime;
        dataSource = 'accuweather';
        
        // Log AccuWeather API usage (2 calls: location + current conditions)
        await supabase.from('weather_api_usage').insert({
          api_provider: 'accuweather',
          endpoint: 'currentconditions + forecast',
          calls_count: 2,
          success: true,
          response_time_ms: responseTime
        });
        
        console.log(`✅ AccuWeather data fetched successfully`);
      } catch (error) {
        console.warn(`⚠️ AccuWeather failed: ${error.message}`);
        apiSuccess = false;
        errorMessage = error.message;
        
        // Log failed attempt
        await supabase.from('weather_api_usage').insert({
          api_provider: 'accuweather',
          endpoint: 'currentconditions + forecast',
          calls_count: 0,
          success: false,
          error_message: error.message
        });
        
        // Fall through to WeatherAPI
        weatherData = null;
      }
    } else {
      console.log("⚠️ AccuWeather daily limit approaching, using WeatherAPI.com fallback");
      weatherData = null;
    }

    // Fallback to WeatherAPI.com if AccuWeather failed or limit reached
    if (!weatherData) {
      console.log("🔄 Falling back to WeatherAPI.com...");
      try {
        const result = await fetchWeatherAPIData(LSPU_LATITUDE, LSPU_LONGITUDE);
        weatherData = result.data;
        responseTime = result.responseTime;
        dataSource = 'weatherapi';
        
        // Log WeatherAPI usage (2 calls: current + forecast)
        await supabase.from('weather_api_usage').insert({
          api_provider: 'weatherapi',
          endpoint: 'current + forecast',
          calls_count: 2,
          success: true,
          response_time_ms: responseTime
        });
        
        console.log(`✅ WeatherAPI.com data fetched successfully`);
      } catch (error) {
        console.error(`❌ WeatherAPI.com also failed: ${error.message}`);
        
        // Log failed attempt
        await supabase.from('weather_api_usage').insert({
          api_provider: 'weatherapi',
          endpoint: 'current + forecast',
          calls_count: 0,
          success: false,
          error_message: error.message
        });
        
        return new Response(JSON.stringify({
          success: false,
          error: 'Both APIs failed',
          details: {
            accuweather: errorMessage,
            weatherapi: error.message
          }
        }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }
    }

    // Update weather cache in database
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 2 * 60 * 60 * 1000); // 2 hours from now

    const cacheUpdate: WeatherCacheUpdate = {
      location_name: LSPU_LOCATION_NAME,
      latitude: LSPU_LATITUDE,
      longitude: LSPU_LONGITUDE,
      temperature: weatherData.temperature,
      feels_like: weatherData.feels_like,
      weather_text: weatherData.weather_text,
      weather_icon: weatherData.weather_icon,
      humidity: weatherData.humidity,
      wind_speed: weatherData.wind_speed,
      wind_direction: weatherData.wind_direction,
      pressure: weatherData.pressure,
      visibility: weatherData.visibility,
      cloud_cover: weatherData.cloud_cover,
      uv_index: weatherData.uv_index,
      rain_1h: weatherData.rain_1h,
      rain_probability: weatherData.daily_forecast?.[0]?.rain_probability || null,
      air_quality_index: weatherData.air_quality_index || null,
      pm2_5: weatherData.pm2_5 || null,
      pm10: weatherData.pm10 || null,
      hourly_forecast: weatherData.hourly_forecast || null,
      daily_forecast: weatherData.daily_forecast || null,
      weather_alerts: weatherData.weather_alerts || null,
      data_source: dataSource,
      last_updated: now.toISOString(),
      cache_expires_at: expiresAt.toISOString()
    };

    const { error: updateError } = await supabase
      .from('weather_cache')
      .upsert(cacheUpdate, {
        onConflict: 'latitude,longitude'
      });

    if (updateError) {
      console.error("❌ Error updating weather cache:", updateError);
      return new Response(JSON.stringify({
        success: false,
        error: 'Failed to update cache',
        details: updateError.message
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    console.log(`✅ Weather cache updated successfully with ${dataSource} data`);

    return new Response(JSON.stringify({
      success: true,
      data_source: dataSource,
      temperature: weatherData.temperature,
      weather_text: weatherData.weather_text,
      last_updated: now.toISOString(),
      cache_expires_at: expiresAt.toISOString(),
      response_time_ms: responseTime,
      api_usage: {
        accuweather_calls_today: totalAccuWeatherCalls + (dataSource === 'accuweather' ? 2 : 0),
        limit: 50
      }
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error("❌ Weather cache update error:", error);
    return new Response(JSON.stringify({
      success: false,
      error: 'Internal server error',
      details: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

