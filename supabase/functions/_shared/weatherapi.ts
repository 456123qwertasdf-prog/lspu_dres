// WeatherAPI.com Integration Module
// Provides functions to interact with WeatherAPI.com API

const WEATHERAPI_KEY = Deno.env.get("WEATHERAPI_KEY") || "";
const WEATHERAPI_BASE_URL = "https://api.weatherapi.com/v1";

export interface WeatherAPIResponse {
  location: {
    name: string;
    region: string;
    country: string;
    lat: number;
    lon: number;
  };
  current: {
    temp_c: number;
    condition: {
      text: string;
      icon: string;
      code: number;
    };
    wind_kph: number;
    wind_degree: number;
    pressure_mb: number;
    precip_mm: number;
    humidity: number;
    cloud: number;
    feelslike_c: number;
    vis_km: number;
    uv: number;
    air_quality?: {
      pm2_5: number;
      pm10: number;
      "us-epa-index": number;
    };
  };
}

export interface WeatherAPIForecast {
  forecast: {
    forecastday: Array<{
      date: string;
      day: {
        maxtemp_c: number;
        mintemp_c: number;
        avgtemp_c: number;
        maxwind_kph: number;
        totalprecip_mm: number;
        avghumidity: number;
        daily_chance_of_rain: number;
        condition: {
          text: string;
          icon: string;
        };
        uv: number;
      };
      hour: Array<{
        time: string;
        temp_c: number;
        condition: {
          text: string;
          icon: string;
        };
        chance_of_rain: number;
        precip_mm: number;
      }>;
    }>;
  };
  alerts?: {
    alert: Array<{
      headline: string;
      msgtype: string;
      severity: string;
      urgency: string;
      areas: string;
      category: string;
      certainty: string;
      event: string;
      note: string;
      effective: string;
      expires: string;
      desc: string;
      instruction: string;
    }>;
  };
}

export interface NormalizedWeatherData {
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
  air_quality_index: number | null;
  pm2_5: number | null;
  pm10: number | null;
  hourly_forecast: any;
  daily_forecast: any;
  weather_alerts: any;
}

/**
 * Fetch current weather from WeatherAPI.com
 */
export async function getCurrentWeather(
  latitude: number,
  longitude: number
): Promise<WeatherAPIResponse> {
  const url = `${WEATHERAPI_BASE_URL}/current.json?key=${WEATHERAPI_KEY}&q=${latitude},${longitude}&aqi=yes`;
  
  const startTime = Date.now();
  
  try {
    const response = await fetch(url);
    const responseTime = Date.now() - startTime;
    
    if (!response.ok) {
      throw new Error(`WeatherAPI current weather error: ${response.status} ${response.statusText}`);
    }
    
    const data: WeatherAPIResponse = await response.json();
    
    console.log(`✅ WeatherAPI.com current weather fetched (${responseTime}ms)`);
    
    return data;
  } catch (error) {
    console.error("❌ Error fetching WeatherAPI.com current weather:", error);
    throw error;
  }
}

/**
 * Fetch forecast from WeatherAPI.com
 */
export async function getForecast(
  latitude: number,
  longitude: number,
  days: number = 7
): Promise<WeatherAPIForecast> {
  const url = `${WEATHERAPI_BASE_URL}/forecast.json?key=${WEATHERAPI_KEY}&q=${latitude},${longitude}&days=${days}&aqi=yes&alerts=yes`;
  
  const startTime = Date.now();
  
  try {
    const response = await fetch(url);
    const responseTime = Date.now() - startTime;
    
    if (!response.ok) {
      throw new Error(`WeatherAPI forecast error: ${response.status} ${response.statusText}`);
    }
    
    const data: WeatherAPIForecast = await response.json();
    
    console.log(`✅ WeatherAPI.com ${days}-day forecast fetched (${responseTime}ms)`);
    
    return data;
  } catch (error) {
    console.error("❌ Error fetching WeatherAPI.com forecast:", error);
    throw error;
  }
}

/**
 * Normalize WeatherAPI.com data to standard format
 */
export function normalizeWeatherAPIData(
  current: WeatherAPIResponse,
  forecast: WeatherAPIForecast
): NormalizedWeatherData {
  return {
    temperature: current.current.temp_c,
    feels_like: current.current.feelslike_c,
    weather_text: current.current.condition.text,
    weather_icon: current.current.condition.code.toString(),
    humidity: current.current.humidity,
    wind_speed: current.current.wind_kph,
    wind_direction: current.current.wind_degree,
    pressure: current.current.pressure_mb,
    visibility: current.current.vis_km,
    cloud_cover: current.current.cloud,
    uv_index: current.current.uv,
    rain_1h: current.current.precip_mm,
    air_quality_index: current.current.air_quality?.["us-epa-index"] || null,
    pm2_5: current.current.air_quality?.pm2_5 || null,
    pm10: current.current.air_quality?.pm10 || null,
    hourly_forecast: forecast.forecast.forecastday[0]?.hour.slice(0, 24).map(hour => ({
      time: hour.time,
      temp: hour.temp_c,
      description: hour.condition.text,
      rain_chance: hour.chance_of_rain,
      rain_volume: hour.precip_mm
    })) || [],
    daily_forecast: forecast.forecast.forecastday.map(day => ({
      date: day.date,
      temp_min: day.day.mintemp_c,
      temp_max: day.day.maxtemp_c,
      day_description: day.day.condition.text,
      rain_probability: day.day.daily_chance_of_rain,
      icon: day.day.condition.icon,
      uv_index: day.day.uv
    })),
    weather_alerts: forecast.alerts?.alert.map(alert => ({
      event: alert.event,
      headline: alert.headline,
      description: alert.desc,
      severity: alert.severity,
      urgency: alert.urgency,
      effective: alert.effective,
      expires: alert.expires,
      instruction: alert.instruction
    })) || []
  };
}

/**
 * Fetch complete weather data from WeatherAPI.com
 */
export async function fetchWeatherAPIData(
  latitude: number,
  longitude: number
): Promise<{ data: NormalizedWeatherData; responseTime: number }> {
  const startTime = Date.now();
  
  try {
    // Fetch current weather and forecast
    const [current, forecast] = await Promise.all([
      getCurrentWeather(latitude, longitude),
      getForecast(latitude, longitude, 7)
    ]);
    
    const data = normalizeWeatherAPIData(current, forecast);
    const responseTime = Date.now() - startTime;
    
    console.log(`✅ WeatherAPI.com data fetched successfully (${responseTime}ms)`);
    
    return { data, responseTime };
  } catch (error) {
    const responseTime = Date.now() - startTime;
    console.error("❌ Error fetching WeatherAPI.com data:", error);
    throw error;
  }
}

