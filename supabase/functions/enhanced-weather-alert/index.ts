import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "https://hmolyqzbvxxliemclrld.supabase.co";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhtb2x5cXpidnh4bGllbWNscmxkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDI0Njk3MCwiZXhwIjoyMDc1ODIyOTcwfQ.496txRbAGuiOov76vxdwSDUHplBt1osOD2PyV0EE958";

const supabase = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { persistSession: false },
});

interface EnhancedWeatherData {
  main: {
    temp: number;
    feels_like: number;
    humidity: number;
    pressure: number;
  };
  weather: Array<{
    main: string;
    description: string;
    icon: string;
  }>;
  wind: {
    speed: number;
    deg: number;
  };
  visibility: number;
  rain?: {
    "1h": number;
  };
  clouds: {
    all: number;
  };
  pop?: number; // Probability of precipitation (rain chance)
  alerts?: Array<{
    sender_name: string;
    event: string;
    start: number;
    end: number;
    description: string;
    tags: string[];
  }>;
  forecast_summary?: {
    next_24h_max_rain_chance: number;
    next_24h_avg_rain_chance: number;
    next_24h_forecast: Array<{
      time: string;
      temp: number;
      rain_chance: number;
      description: string;
      rain_volume: number;
    }>;
  } | null;
}

interface WeatherAlert {
  type: string;
  priority: string;
  title: string;
  message: string;
  expires_at: string;
}

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Validate request method
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Parse and validate request body
    let requestData;
    try {
      requestData = await req.json();
    } catch (error) {
      return new Response(JSON.stringify({ error: 'Invalid JSON in request body' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { latitude, longitude, city } = requestData;
    
    if (!latitude || !longitude) {
      return new Response(JSON.stringify({ error: 'latitude and longitude required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Use new LSPU coordinates if not provided
  const finalLatitude = latitude || 14.26284;
  const finalLongitude = longitude || 121.39743;
    const finalCity = city || "LSPU Sta. Cruz Campus, Laguna, Philippines";

    console.log(`🌤️ Fetching weather data for: ${finalCity} (${finalLatitude}, ${finalLongitude})`);

    // Get enhanced weather data
    const weatherData = await getEnhancedWeatherData(finalLatitude, finalLongitude);
    
    // Analyze weather conditions for comprehensive alerts
    const alerts = analyzeEnhancedWeatherConditions(weatherData, finalCity);
    
    // Create weather alerts in database
    const alertsCreated = await createWeatherAlerts(alerts);
    
    // Send notifications for new alerts
    if (alertsCreated > 0) {
      await sendWeatherNotifications(alerts);
    }

    return new Response(JSON.stringify({
      success: true,
      weather_data: weatherData,
      alerts_created: alertsCreated,
      alerts: alerts
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error('❌ Enhanced weather alert error:', error);
    return new Response(JSON.stringify({ 
      error: 'Internal server error',
      details: error.message 
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

// Get enhanced weather data from cache (AccuWeather or WeatherAPI fallback)
async function getEnhancedWeatherData(latitude: number, longitude: number): Promise<EnhancedWeatherData> {
  try {
    console.log(`🔍 Looking for weather cache at (${latitude}, ${longitude})`);
    
    // Fetch from weather cache using proximity search (handles decimal precision)
    // DECIMAL(10,8) in database vs JavaScript number precision can cause exact match failures
    const { data: allCache } = await supabase
      .from('weather_cache')
      .select('*');
    
    console.log(`📊 Found ${allCache?.length || 0} cache entries`);
    
    // Find closest match (within ~100 meters)
    const cachedWeather = allCache?.find(cache => {
      const latDiff = Math.abs(cache.latitude - latitude);
      const lonDiff = Math.abs(cache.longitude - longitude);
      return latDiff < 0.001 && lonDiff < 0.001;
    });

    if (!cachedWeather) {
      console.warn(`⚠️ Weather cache not found for coords (${latitude}, ${longitude})`);
      console.log('Available cache entries:', allCache);
      
      // Trigger cache update asynchronously
      try {
        await fetch(`${SUPABASE_URL}/functions/v1/update-weather-cache`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${SERVICE_KEY}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ location: 'LSPU' })
        });
      } catch (updateError) {
        console.error('❌ Failed to trigger cache update:', updateError);
      }
      
      throw new Error('Weather cache not available. Please try again in a few moments.');
    }
    
    console.log(`✅ Found weather cache at (${cachedWeather.latitude}, ${cachedWeather.longitude}) for request (${latitude}, ${longitude})`);

    // Check if cache is stale (older than 3 hours)
    const cacheAge = Date.now() - new Date(cachedWeather.last_updated).getTime();
    const threeHoursInMs = 3 * 60 * 60 * 1000;
    
    if (cacheAge > threeHoursInMs) {
      console.warn(`⚠️ Weather cache is stale (${Math.round(cacheAge / 1000 / 60)} minutes old)`);
      
      // Trigger cache update asynchronously (don't wait)
      fetch(`${SUPABASE_URL}/functions/v1/update-weather-cache`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${SERVICE_KEY}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ location: 'LSPU' })
      }).catch(err => console.error('Failed to update stale cache:', err));
    }

    console.log(`✅ Using cached weather data from ${cachedWeather.data_source} (updated: ${cachedWeather.last_updated})`);

    // Process hourly forecast for 24h summary
    let forecastSummary: {
      next_24h_max_rain_chance: number;
      next_24h_avg_rain_chance: number;
      next_24h_forecast: Array<{
        time: string;
        temp: number;
        rain_chance: number;
        description: string;
        rain_volume: number;
      }>;
    } | null = null;
    
    if (cachedWeather.hourly_forecast && Array.isArray(cachedWeather.hourly_forecast)) {
      const next24Hours = cachedWeather.hourly_forecast.slice(0, 24);
      const rainChances = next24Hours.map(item => item.rain_chance || 0);
      const maxRainChance = Math.max(...rainChances) / 100; // Convert from percentage
      const avgRainChance = rainChances.reduce((sum, chance) => sum + chance, 0) / rainChances.length / 100;
      
      forecastSummary = {
        next_24h_max_rain_chance: maxRainChance,
        next_24h_avg_rain_chance: avgRainChance,
        next_24h_forecast: next24Hours.map(item => ({
          time: item.time,
          temp: item.temp,
          rain_chance: (item.rain_chance || 0) / 100,
          description: item.description,
          rain_volume: item.rain_volume || 0
        }))
      };
    } else if (cachedWeather.daily_forecast && Array.isArray(cachedWeather.daily_forecast)) {
      // Fallback to daily forecast if hourly not available (AccuWeather free tier)
      const today = cachedWeather.daily_forecast[0];
      const maxRainChance = (today?.rain_probability || 0) / 100;
      
      forecastSummary = {
        next_24h_max_rain_chance: maxRainChance,
        next_24h_avg_rain_chance: maxRainChance,
        next_24h_forecast: []
      };
    }

    // Normalize cached data to EnhancedWeatherData format
    return {
      main: {
        temp: cachedWeather.temperature,
        feels_like: cachedWeather.feels_like,
        humidity: cachedWeather.humidity,
        pressure: cachedWeather.pressure
      },
      weather: [{
        main: cachedWeather.weather_text,
        description: cachedWeather.weather_text,
        icon: cachedWeather.weather_icon
      }],
      wind: {
        speed: cachedWeather.wind_speed / 3.6, // Convert km/h to m/s for consistency
        deg: cachedWeather.wind_direction
      },
      visibility: cachedWeather.visibility * 1000, // Convert km to meters
      rain: cachedWeather.rain_1h ? { "1h": cachedWeather.rain_1h } : undefined,
      clouds: {
        all: cachedWeather.cloud_cover
      },
      pop: (cachedWeather.rain_probability || 0) / 100,
      alerts: cachedWeather.weather_alerts || [],
      forecast_summary: forecastSummary || null
    };

  } catch (error) {
    console.error('❌ Error fetching weather data from cache:', error);
    throw error;
  }
}

// Analyze enhanced weather conditions for comprehensive alerts
function analyzeEnhancedWeatherConditions(data: EnhancedWeatherData, city: string): WeatherAlert[] {
  const alerts: WeatherAlert[] = [];
  const now = new Date();
  const expiresAt = new Date(now.getTime() + 6 * 60 * 60 * 1000); // 6 hours from now

  // Temperature and Heat Index Analysis
  const temp = data.main.temp;
  const heatIndex = data.main.feels_like;
  const humidity = data.main.humidity;

  if (heatIndex >= 40) {
    alerts.push({
      type: "weather",
      priority: "high",
      title: "🌡️ Extreme Heat Warning",
      message: `Extreme heat index of ${Math.round(heatIndex)}°C detected in ${city}. Avoid outdoor activities and stay hydrated.`,
      expires_at: expiresAt.toISOString()
    });
  } else if (heatIndex >= 35) {
    alerts.push({
      type: "weather",
      priority: "medium",
      title: "🌡️ High Heat Advisory",
      message: `High heat index of ${Math.round(heatIndex)}°C in ${city}. Take precautions and stay cool.`,
      expires_at: expiresAt.toISOString()
    });
  }

  // Rain Analysis
  const rainVolume = data.rain?.["1h"] || 0;
  const rainChance = (data.pop || 0) * 100;
  const maxRainChance = (data.forecast_summary?.next_24h_max_rain_chance ?? 0) * 100;

  if (rainVolume >= 7.5) {
    alerts.push({
      type: "weather",
      priority: "high",
      title: "🌧️ Heavy Rainfall Warning",
      message: `Heavy rainfall of ${rainVolume}mm/hour detected in ${city}. Risk of flooding. Avoid low-lying areas.`,
      expires_at: expiresAt.toISOString()
    });
  } else if (rainVolume >= 2.5) {
    alerts.push({
      type: "weather",
      priority: "medium",
      title: "🌧️ Moderate Rainfall Alert",
      message: `Moderate rainfall of ${rainVolume}mm/hour in ${city}. Stay indoors if possible.`,
      expires_at: expiresAt.toISOString()
    });
  }

  if (maxRainChance >= 80) {
    alerts.push({
      type: "weather",
      priority: "medium",
      title: "🌦️ High Rain Probability",
      message: `Very high chance of rain (${Math.round(maxRainChance)}%) expected in ${city} within 24 hours.`,
      expires_at: expiresAt.toISOString()
    });
  }

  // Wind Analysis
  const windSpeed = data.wind.speed * 3.6; // Convert m/s to km/h
  if (windSpeed >= 50) {
    alerts.push({
      type: "weather",
      priority: "high",
      title: "💨 Strong Wind Warning",
      message: `Strong winds of ${Math.round(windSpeed)} km/h in ${city}. Secure loose objects and avoid outdoor activities.`,
      expires_at: expiresAt.toISOString()
    });
  } else if (windSpeed >= 30) {
    alerts.push({
      type: "weather",
      priority: "medium",
      title: "💨 Wind Advisory",
      message: `Moderate winds of ${Math.round(windSpeed)} km/h in ${city}. Be cautious outdoors.`,
      expires_at: expiresAt.toISOString()
    });
  }

  // Thunderstorm Analysis
  const weatherMain = data.weather[0]?.main?.toLowerCase() || '';
  const weatherDescription = data.weather[0]?.description?.toLowerCase() || '';
  
  if (weatherMain.includes('thunderstorm') || weatherDescription.includes('thunderstorm')) {
    alerts.push({
      type: "weather",
      priority: "high",
      title: "⛈️ Thunderstorm Warning",
      message: `Thunderstorm activity detected in ${city}. Seek shelter immediately and avoid open areas.`,
      expires_at: expiresAt.toISOString()
    });
  }

  // Visibility Analysis
  const visibility = data.visibility / 1000; // Convert to km
  if (visibility < 1) {
    alerts.push({
      type: "weather",
      priority: "high",
      title: "🌫️ Dense Fog Warning",
      message: `Very poor visibility (${visibility.toFixed(1)}km) in ${city}. Drive with extreme caution.`,
      expires_at: expiresAt.toISOString()
    });
  } else if (visibility < 5) {
    alerts.push({
      type: "weather",
      priority: "medium",
      title: "🌫️ Reduced Visibility",
      message: `Reduced visibility (${visibility.toFixed(1)}km) in ${city}. Drive carefully.`,
      expires_at: expiresAt.toISOString()
    });
  }

  // Air Quality Analysis (Simplified)
  const aqi = calculateSimplifiedAQI(data.main.pressure, humidity);
  if (aqi >= 150) {
    alerts.push({
      type: "weather",
      priority: "medium",
      title: "🌫️ Poor Air Quality",
      message: `Poor air quality detected in ${city}. Limit outdoor activities, especially for sensitive individuals.`,
      expires_at: expiresAt.toISOString()
    });
  }

  // Official Weather Alerts
  if (data.alerts && data.alerts.length > 0) {
    data.alerts.forEach(alert => {
      alerts.push({
        type: "weather",
        priority: "high",
        title: `⚠️ ${alert.event}`,
        message: `${alert.description} - Valid until ${new Date(alert.end * 1000).toLocaleString()}`,
        expires_at: expiresAt.toISOString()
      });
    });
  }

  return alerts;
}

// Calculate simplified AQI based on pressure and humidity
function calculateSimplifiedAQI(pressure: number, humidity: number): number {
  // Simplified AQI calculation based on atmospheric conditions
  // This is a basic approximation - real AQI requires pollutant measurements
  const baseAQI = 50; // Base good air quality
  const pressureFactor = Math.max(0, (1013 - pressure) / 10); // Higher pressure = better air
  const humidityFactor = Math.max(0, (humidity - 60) / 20); // Higher humidity = worse air
  
  return Math.round(baseAQI + pressureFactor + humidityFactor);
}

// Create weather alerts in database
async function createWeatherAlerts(alerts: WeatherAlert[]): Promise<number> {
  if (alerts.length === 0) return 0;

  let alertsCreated = 0;
  const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);

  for (const alert of alerts) {
    try {
      // Check for duplicate alerts within 2 hours
      const { data: existingAlerts } = await supabase
        .from('announcements')
        .select('id')
        .eq('type', 'weather')
        .eq('title', alert.title)
        .gte('created_at', twoHoursAgo.toISOString());

      if (existingAlerts && existingAlerts.length > 0) {
        console.log(`⚠️ Duplicate alert prevented: ${alert.title}`);
        continue;
      }

      // Create new alert
      const { error } = await supabase
        .from('announcements')
        .insert({
          title: alert.title,
          message: alert.message,
          type: alert.type,
          priority: alert.priority,
          status: 'active',
          target_audience: 'all',
          created_by: 'system',
          expires_at: alert.expires_at
        });

      if (error) {
        console.error('❌ Error creating weather alert:', error);
      } else {
        alertsCreated++;
        console.log(`✅ Weather alert created: ${alert.title}`);
      }
    } catch (error) {
      console.error('❌ Error processing weather alert:', error);
    }
  }

  return alertsCreated;
}

// Send weather notifications
async function sendWeatherNotifications(alerts: WeatherAlert[]): Promise<void> {
  if (alerts.length === 0) return;

  try {
    const response = await fetch(`${SUPABASE_URL}/functions/v1/announcement-notify`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SERVICE_KEY}`
      },
      body: JSON.stringify({
        type: 'weather',
        alerts: alerts
      })
    });

    if (!response.ok) {
      console.error('❌ Error sending weather notifications:', response.statusText);
    } else {
      console.log('✅ Weather notifications sent successfully');
    }
  } catch (error) {
    console.error('❌ Error sending weather notifications:', error);
  }
}