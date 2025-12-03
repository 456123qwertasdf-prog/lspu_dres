# Weather API Setup Guide

## Overview

The LSPU DRES system now uses a dual-API weather strategy for optimal accuracy and reliability:

- **Primary**: AccuWeather (highest accuracy, free tier with caching)
- **Fallback**: WeatherAPI.com (includes Air Quality data, generous free tier)

### Architecture

```
┌─────────────────────────────────────────────┐
│   SCHEDULED CRON JOB (Every 2 hours)       │
│   supabase/functions/update-weather-cache   │
└─────────────────┬───────────────────────────┘
                  │
                  ↓
         Try AccuWeather First
         (if under daily limit)
                  │
         ┌────────┴────────┐
         │   SUCCESS?      │
         └────────┬────────┘
              YES │        NO
                  │        │
                  │        ↓
                  │   Fallback to
                  │   WeatherAPI.com
                  │        │
                  └────┬───┘
                       │
                       ↓
              ┌────────────────┐
              │ DATABASE CACHE │
              │ weather_cache  │
              └────────┬───────┘
                       │
                       ↓
         ┌─────────────────────────┐
         │ USERS READ FROM CACHE   │
         │ (Unlimited, no API cost)│
         └─────────────────────────┘
```

## Benefits

✅ **AccuWeather accuracy** with free tier (50 calls/day)  
✅ **WeatherAPI.com Air Quality data** (PM2.5, PM10, AQI)  
✅ **Automatic fallback** for reliability  
✅ **Unlimited users** via database caching  
✅ **Cost**: ₱0/month  
✅ **12 scheduled updates/day** = well within 50 call limit

---

## Setup Instructions

### 1. Get API Keys

#### AccuWeather (Primary)

1. Visit: https://developer.accuweather.com/
2. Sign up for a free account
3. Create a new app
4. Copy your API Key
5. **Free Tier**: 50 calls/day

#### WeatherAPI.com (Fallback)

1. Visit: https://www.weatherapi.com/
2. Sign up for a free account
3. Copy your API Key from the dashboard
4. **Free Tier**: 1,000,000 calls/month (includes AQI)

### 2. Configure Supabase Secrets

Run these commands in your terminal:

```bash
# Set AccuWeather API key
supabase secrets set ACCUWEATHER_API_KEY=your_accuweather_key_here

# Set WeatherAPI.com key
supabase secrets set WEATHERAPI_KEY=your_weatherapi_key_here
```

Verify secrets are set:

```bash
supabase secrets list
```

### 3. Deploy Database Migrations

Deploy the new weather cache tables and cron job:

```bash
# Deploy migrations
supabase db push

# Or apply specific migrations
supabase migration up
```

This creates:
- `weather_cache` table (stores weather data)
- `weather_api_usage` table (tracks API calls)
- Cron job (updates cache every 2 hours)

### 4. Deploy Edge Functions

Deploy the new weather cache update function:

```bash
# Deploy update-weather-cache function
supabase functions deploy update-weather-cache

# The enhanced-weather-alert function is already deployed
# but redeploy it to use the updated code
supabase functions deploy enhanced-weather-alert
```

### 5. Initialize Weather Cache

Manually trigger the first cache update:

```bash
curl -X POST https://hmolyqzbvxxliemclrld.supabase.co/functions/v1/update-weather-cache \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"location": "LSPU"}'
```

Or run this SQL query in Supabase SQL Editor:

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

## How It Works

### Automatic Cache Updates

The system automatically updates weather data every 2 hours:

```
Schedule: 12:00 AM, 2:00 AM, 4:00 AM, 6:00 AM, 8:00 AM, 10:00 AM,
          12:00 PM, 2:00 PM, 4:00 PM, 6:00 PM, 8:00 PM, 10:00 PM

Total: 12 updates/day
AccuWeather usage: ~24 calls/day (2 calls per update)
Remaining buffer: 26 calls for manual triggers/errors
```

### API Selection Logic

```typescript
1. Check AccuWeather daily usage
   ├─ If < 45 calls → Try AccuWeather
   │   ├─ SUCCESS → Update cache, done
   │   └─ FAIL → Fallback to WeatherAPI.com
   └─ If ≥ 45 calls → Use WeatherAPI.com directly
```

### User Access

- All users read from `weather_cache` table
- No direct API calls from frontend
- Unlimited users, zero additional API cost
- Data freshness: Max 2 hours old

---

## Monitoring & Maintenance

### Check API Usage

View today's API usage:

```sql
SELECT 
  api_provider,
  COUNT(*) as total_calls,
  SUM(calls_count) as api_calls,
  AVG(response_time_ms) as avg_response_time,
  COUNT(*) FILTER (WHERE success = false) as failures
FROM weather_api_usage
WHERE created_at >= CURRENT_DATE
GROUP BY api_provider;
```

### View Weather Cache Status

```sql
SELECT 
  location_name,
  temperature,
  weather_text,
  data_source,
  last_updated,
  AGE(NOW(), last_updated) as cache_age
FROM weather_cache;
```

### Check Cron Job Status

```sql
-- View cron job schedule
SELECT * FROM cron.job 
WHERE jobname = 'update-weather-cache-every-2hrs';

-- View recent cron job runs
SELECT * FROM cron.job_run_details 
WHERE jobid = (
  SELECT jobid FROM cron.job 
  WHERE jobname = 'update-weather-cache-every-2hrs'
)
ORDER BY start_time DESC 
LIMIT 10;
```

### Manual Cache Update

Trigger cache update manually (useful for testing):

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

## Troubleshooting

### Issue: Cache not updating

**Check cron job:**
```sql
SELECT * FROM cron.job WHERE jobname = 'update-weather-cache-every-2hrs';
```

**Check recent errors:**
```sql
SELECT * FROM weather_api_usage 
WHERE success = false 
ORDER BY created_at DESC 
LIMIT 10;
```

### Issue: AccuWeather rate limit exceeded

- System automatically falls back to WeatherAPI.com
- Check usage: Should be ~24 calls/day
- If consistently exceeding, verify cron schedule

### Issue: Both APIs failing

**Check API keys:**
```bash
supabase secrets list
```

**Verify connectivity:**
```bash
# Test AccuWeather
curl "http://dataservice.accuweather.com/locations/v1/cities/geoposition/search?apikey=YOUR_KEY&q=14.262585,121.398436"

# Test WeatherAPI.com
curl "https://api.weatherapi.com/v1/current.json?key=YOUR_KEY&q=14.262585,121.398436"
```

### Issue: Stale cache data

The system auto-updates every 2 hours. If data is stale:

1. Check if cron job is running
2. Manually trigger update (see above)
3. Check Edge Function logs:

```bash
supabase functions logs update-weather-cache --tail
```

---

## Cost Analysis

### Current Setup

| Metric | Value |
|--------|-------|
| **AccuWeather calls/day** | 12-24 |
| **AccuWeather free limit** | 50/day |
| **WeatherAPI calls/month** | 0-720 (fallback only) |
| **WeatherAPI free limit** | 1,000,000/month |
| **Total cost** | **₱0/month** |
| **Users supported** | **Unlimited** |

### Compared to Direct API Calls

**Without caching** (1,000 users, 2 checks/day):
- API calls needed: 2,000/day
- AccuWeather cost: ~₱1,500-2,500/month
- **Annual savings: ₱18,000-30,000**

---

## Data Available

### From AccuWeather (Primary)

✅ Temperature, feels like  
✅ Humidity, pressure  
✅ Wind speed & direction  
✅ UV Index  
✅ Cloud cover  
✅ Visibility  
✅ 5-day forecast  
✅ Weather alerts  
❌ Air Quality (paid tier only)  
❌ Hourly forecast (paid tier only)

### From WeatherAPI.com (Fallback)

✅ Temperature, feels like  
✅ Humidity, pressure  
✅ Wind speed & direction  
✅ UV Index  
✅ Cloud cover  
✅ Visibility  
✅ **Air Quality (PM2.5, PM10, AQI)** ⭐  
✅ **Hourly forecast** ⭐  
✅ 7-14 day forecast  
✅ Weather alerts

---

## Frontend Integration

No changes needed! The existing `enhanced-weather-alert` function now reads from cache:

```javascript
// Frontend code remains unchanged
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

The function automatically:
1. Reads from cache
2. Returns cached data if fresh (< 3 hours)
3. Triggers cache update if stale
4. Shows which API source was used

---

## Future Enhancements

### Potential additions:

1. **Multiple locations**: Support caching for multiple campuses
2. **Predictive caching**: Update more frequently during severe weather
3. **Health indices**: Calculate custom health/activity scores
4. **PAGASA integration**: Add official Philippine weather alerts
5. **Historical data**: Store weather history for analysis

---

## Support

For issues or questions:
1. Check Supabase function logs
2. Review API usage tables
3. Verify cron job is running
4. Check API key validity

**System Status Dashboard**: Monitor weather cache and API usage via Supabase dashboard.

