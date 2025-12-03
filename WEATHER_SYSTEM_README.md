# Weather System - Quick Reference

## 🌤️ Overview

The LSPU DRES system uses a dual-API weather strategy with database caching:

- **Primary:** AccuWeather (highest accuracy)
- **Fallback:** WeatherAPI.com (includes Air Quality)
- **Caching:** Supabase database (unlimited users, ₱0 cost)

---

## 🚀 Quick Start

### 1. Get API Keys

**AccuWeather:** https://developer.accuweather.com/ (Free: 50 calls/day)  
**WeatherAPI:** https://www.weatherapi.com/ (Free: 1M calls/month)

### 2. Set Secrets

```bash
supabase secrets set ACCUWEATHER_API_KEY=your_key
supabase secrets set WEATHERAPI_KEY=your_key
```

### 3. Deploy

```bash
supabase db push
supabase functions deploy update-weather-cache
supabase functions deploy enhanced-weather-alert
```

### 4. Initialize Cache

```sql
SELECT net.http_post(
  url := 'https://hmolyqzbvxxliemclrld.supabase.co/functions/v1/update-weather-cache',
  headers := jsonb_build_object(
    'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY',
    'Content-Type', 'application/json'
  ),
  body := '{"location": "LSPU"}'::jsonb
);
```

---

## 📁 File Structure

```
supabase/
├── migrations/
│   ├── 20250203120000_create_weather_cache.sql    # Tables & policies
│   └── 20250203120001_setup_weather_cron.sql      # Scheduled updates
├── functions/
│   ├── _shared/
│   │   ├── accuweather.ts                         # AccuWeather API
│   │   └── weatherapi.ts                          # WeatherAPI.com
│   ├── update-weather-cache/
│   │   └── index.ts                               # Cache update logic
│   └── enhanced-weather-alert/
│       └── index.ts                               # User-facing API

Documentation/
├── WEATHER_API_SETUP.md                           # Full setup guide
├── WEATHER_API_DEPLOYMENT_CHECKLIST.md            # Deployment steps
├── IMPLEMENTATION_SUMMARY.md                      # Technical details
└── WEATHER_SYSTEM_README.md                       # This file
```

---

## 🔄 How It Works

```
Every 2 hours:
1. Cron job triggers update-weather-cache
2. Function checks AccuWeather usage (< 45 calls?)
   ├─ YES → Fetch from AccuWeather
   └─ NO → Use WeatherAPI.com
3. Store data in weather_cache table
4. All users read from cache (unlimited, fast, free)
```

---

## 📊 Key Tables

### `weather_cache`
Stores current weather data:
- Location: LSPU coordinates (14.262585, 121.398436)
- Data: Temperature, humidity, wind, UV, etc.
- Source: 'accuweather' or 'weatherapi'
- Freshness: Updated every 2 hours

### `weather_api_usage`
Tracks API calls:
- Provider: 'accuweather' or 'weatherapi'
- Count: Number of API calls
- Success: true/false
- Response time

---

## 🛠️ Common Commands

### Check Cache Status
```sql
SELECT 
  temperature,
  weather_text,
  data_source,
  AGE(NOW(), last_updated) as age
FROM weather_cache;
```

### Monitor API Usage Today
```sql
SELECT 
  api_provider,
  SUM(calls_count) as total_calls
FROM weather_api_usage
WHERE created_at >= CURRENT_DATE
GROUP BY api_provider;
```

### Manual Cache Update
```bash
curl -X POST https://hmolyqzbvxxliemclrld.supabase.co/functions/v1/update-weather-cache \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"location": "LSPU"}'
```

### Check Cron Job
```sql
SELECT * FROM cron.job 
WHERE jobname = 'update-weather-cache-every-2hrs';
```

### View Function Logs
```bash
supabase functions logs update-weather-cache --tail
supabase functions logs enhanced-weather-alert --tail
```

---

## 🎯 API Endpoints

### For Users (Frontend)
**Endpoint:** `enhanced-weather-alert`  
**Method:** POST  
**Usage:** Reads from cache, no direct API calls

```javascript
const response = await fetch(
  'https://hmolyqzbvxxliemclrld.supabase.co/functions/v1/enhanced-weather-alert',
  {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
    },
    body: JSON.stringify({
      latitude: 14.262585,
      longitude: 121.398436,
      city: "LSPU Sta. Cruz Campus"
    })
  }
);
```

### For System (Cron/Admin)
**Endpoint:** `update-weather-cache`  
**Method:** POST  
**Usage:** Updates cache from APIs

```javascript
const response = await fetch(
  'https://hmolyqzbvxxliemclrld.supabase.co/functions/v1/update-weather-cache',
  {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${SERVICE_ROLE_KEY}`
    },
    body: JSON.stringify({ location: 'LSPU' })
  }
);
```

---

## 📈 Monitoring Dashboard

### Health Check Query
```sql
SELECT 
  'Cache Status' as metric,
  CASE 
    WHEN AGE(NOW(), last_updated) < interval '3 hours' THEN '✅ Fresh'
    ELSE '⚠️ Stale'
  END as status,
  data_source as source
FROM weather_cache

UNION ALL

SELECT 
  'API Usage Today',
  SUM(calls_count)::text || '/50',
  api_provider
FROM weather_api_usage 
WHERE created_at >= CURRENT_DATE AND api_provider = 'accuweather'
GROUP BY api_provider;
```

---

## ⚠️ Troubleshooting

### Cache Not Updating
```sql
-- Check cron job
SELECT * FROM cron.job WHERE jobname = 'update-weather-cache-every-2hrs';

-- Check recent errors
SELECT * FROM weather_api_usage 
WHERE success = false 
ORDER BY created_at DESC 
LIMIT 5;
```

### API Rate Limit
```sql
-- Check today's usage
SELECT 
  api_provider,
  SUM(calls_count) as calls
FROM weather_api_usage
WHERE created_at >= CURRENT_DATE
GROUP BY api_provider;

-- Expected: AccuWeather < 30 calls/day
```

### Both APIs Failing
```bash
# Verify API keys
supabase secrets list

# Test AccuWeather
curl "http://dataservice.accuweather.com/locations/v1/cities/geoposition/search?apikey=YOUR_KEY&q=14.262585,121.398436"

# Test WeatherAPI
curl "https://api.weatherapi.com/v1/current.json?key=YOUR_KEY&q=14.262585,121.398436"
```

---

## 💰 Cost Breakdown

| Component | Cost |
|-----------|------|
| AccuWeather API | ₱0 (free tier, 50/day) |
| WeatherAPI.com | ₱0 (free tier, 1M/month) |
| Supabase storage | ₱0 (minimal data) |
| Supabase functions | ₱0 (within free tier) |
| **Total** | **₱0/month** |

**Savings:** ₱18,000-30,000/year vs direct API calls

---

## ✅ Success Indicators

- [ ] Cache updates every 2 hours
- [ ] AccuWeather calls: 12-24/day
- [ ] WeatherAPI calls: 0-12/day (fallback only)
- [ ] Zero frontend errors
- [ ] Weather data displays correctly
- [ ] Air Quality data available
- [ ] Response time < 500ms

---

## 📚 Documentation

**Quick Start:** This file  
**Full Setup:** `WEATHER_API_SETUP.md`  
**Deployment:** `WEATHER_API_DEPLOYMENT_CHECKLIST.md`  
**Technical:** `IMPLEMENTATION_SUMMARY.md`

---

## 🆘 Need Help?

1. Check function logs
2. Review API usage tables
3. Verify cron job is running
4. Consult full documentation
5. Test API keys manually

---

**Status:** ✅ Production Ready  
**Last Updated:** 2025-02-03  
**Version:** 1.0.0

