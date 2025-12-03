// AccuWeather API Integration Module
// Provides functions to interact with AccuWeather API

const ACCUWEATHER_API_KEY = Deno.env.get("ACCUWEATHER_API_KEY") || "";
const ACCUWEATHER_BASE_URL = "http://dataservice.accuweather.com";

export interface AccuWeatherLocation {
  Key: string;
  LocalizedName: string;
  Country: { LocalizedName: string };
}

export interface AccuWeatherCurrentConditions {
  LocalObservationDateTime: string;
  EpochTime: number;
  WeatherText: string;
  WeatherIcon: number;
  Temperature: {
    Metric: { Value: number; Unit: string };
  };
  RealFeelTemperature: {
    Metric: { Value: number };
  };
  RelativeHumidity: number;
  Wind: {
    Speed: { Metric: { Value: number } };
    Direction: { Degrees: number };
  };
  UVIndex: number;
  UVIndexText: string;
  Visibility: {
    Metric: { Value: number };
  };
  CloudCover: number;
  Pressure: {
    Metric: { Value: number };
  };
  PrecipitationSummary?: {
    PastHour?: { Metric?: { Value: number } };
  };
}

export interface AccuWeatherForecast {
  Headline: {
    Text: string;
    Category: string;
    Severity: number;
  };
  DailyForecasts: Array<{
    Date: string;
    Temperature: {
      Minimum: { Value: number };
      Maximum: { Value: number };
    };
    Day: {
      Icon: number;
      IconPhrase: string;
      PrecipitationProbability: number;
    };
    Night: {
      Icon: number;
      IconPhrase: string;
    };
  }>;
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
  hourly_forecast: any;
  daily_forecast: any;
  weather_alerts: any;
}

// Cache for location key (only needs to be fetched once per location)
let cachedLocationKey: string | null = null;

/**
 * Get AccuWeather location key from coordinates
 * This is cached as it only needs to be called once
 */
export async function getLocationKey(
  latitude: number,
  longitude: number
): Promise<string> {
  if (cachedLocationKey) {
    return cachedLocationKey;
  }

  const url = `${ACCUWEATHER_BASE_URL}/locations/v1/cities/geoposition/search?apikey=${ACCUWEATHER_API_KEY}&q=${latitude},${longitude}`;
  
  const startTime = Date.now();
  
  try {
    const response = await fetch(url);
    const responseTime = Date.now() - startTime;
    
    if (!response.ok) {
      throw new Error(`AccuWeather location API error: ${response.status} ${response.statusText}`);
    }
    
    const data: AccuWeatherLocation = await response.json();
    cachedLocationKey = data.Key;
    
    console.log(`✅ AccuWeather location key obtained: ${cachedLocationKey} (${responseTime}ms)`);
    
    return cachedLocationKey;
  } catch (error) {
    console.error("❌ Error fetching AccuWeather location key:", error);
    throw error;
  }
}

/**
 * Fetch current conditions from AccuWeather
 */
export async function getCurrentConditions(
  locationKey: string
): Promise<AccuWeatherCurrentConditions> {
  const url = `${ACCUWEATHER_BASE_URL}/currentconditions/v1/${locationKey}?apikey=${ACCUWEATHER_API_KEY}&details=true`;
  
  const startTime = Date.now();
  
  try {
    const response = await fetch(url);
    const responseTime = Date.now() - startTime;
    
    if (!response.ok) {
      if (response.status === 503) {
        throw new Error("RATE_LIMIT_EXCEEDED");
      }
      throw new Error(`AccuWeather current conditions API error: ${response.status} ${response.statusText}`);
    }
    
    const data = await response.json();
    
    console.log(`✅ AccuWeather current conditions fetched (${responseTime}ms)`);
    
    return data[0]; // API returns array with single item
  } catch (error) {
    console.error("❌ Error fetching AccuWeather current conditions:", error);
    throw error;
  }
}

/**
 * Fetch 5-day forecast from AccuWeather
 */
export async function get5DayForecast(
  locationKey: string
): Promise<AccuWeatherForecast> {
  const url = `${ACCUWEATHER_BASE_URL}/forecasts/v1/daily/5day/${locationKey}?apikey=${ACCUWEATHER_API_KEY}&details=true&metric=true`;
  
  const startTime = Date.now();
  
  try {
    const response = await fetch(url);
    const responseTime = Date.now() - startTime;
    
    if (!response.ok) {
      if (response.status === 503) {
        throw new Error("RATE_LIMIT_EXCEEDED");
      }
      throw new Error(`AccuWeather forecast API error: ${response.status} ${response.statusText}`);
    }
    
    const data: AccuWeatherForecast = await response.json();
    
    console.log(`✅ AccuWeather 5-day forecast fetched (${responseTime}ms)`);
    
    return data;
  } catch (error) {
    console.error("❌ Error fetching AccuWeather forecast:", error);
    throw error;
  }
}

/**
 * Normalize AccuWeather data to standard format
 */
export function normalizeAccuWeatherData(
  current: AccuWeatherCurrentConditions,
  forecast: AccuWeatherForecast
): NormalizedWeatherData {
  return {
    temperature: current.Temperature.Metric.Value,
    feels_like: current.RealFeelTemperature.Metric.Value,
    weather_text: current.WeatherText,
    weather_icon: current.WeatherIcon.toString(),
    humidity: current.RelativeHumidity,
    wind_speed: current.Wind.Speed.Metric.Value,
    wind_direction: current.Wind.Direction.Degrees,
    pressure: current.Pressure.Metric.Value,
    visibility: current.Visibility.Metric.Value,
    cloud_cover: current.CloudCover,
    uv_index: current.UVIndex,
    rain_1h: current.PrecipitationSummary?.PastHour?.Metric?.Value || 0,
    hourly_forecast: null, // AccuWeather free tier doesn't include hourly
    daily_forecast: forecast.DailyForecasts.map(day => ({
      date: day.Date,
      temp_min: day.Temperature.Minimum.Value,
      temp_max: day.Temperature.Maximum.Value,
      day_description: day.Day.IconPhrase,
      rain_probability: day.Day.PrecipitationProbability,
      icon: day.Day.Icon
    })),
    weather_alerts: forecast.Headline.Severity > 3 ? [{
      event: forecast.Headline.Category,
      description: forecast.Headline.Text,
      severity: forecast.Headline.Severity
    }] : []
  };
}

/**
 * Fetch complete weather data from AccuWeather
 */
export async function fetchAccuWeatherData(
  latitude: number,
  longitude: number
): Promise<{ data: NormalizedWeatherData; responseTime: number }> {
  const startTime = Date.now();
  
  try {
    // Get location key (cached after first call)
    const locationKey = await getLocationKey(latitude, longitude);
    
    // Fetch current conditions and forecast
    const [current, forecast] = await Promise.all([
      getCurrentConditions(locationKey),
      get5DayForecast(locationKey)
    ]);
    
    const data = normalizeAccuWeatherData(current, forecast);
    const responseTime = Date.now() - startTime;
    
    console.log(`✅ AccuWeather data fetched successfully (${responseTime}ms)`);
    
    return { data, responseTime };
  } catch (error) {
    const responseTime = Date.now() - startTime;
    console.error("❌ Error fetching AccuWeather data:", error);
    throw error;
  }
}

