# Weather API Deployment Checklist

Follow this checklist to deploy the new AccuWeather + WeatherAPI fallback system.

---

## Pre-Deployment

### ✅ Step 1: Get API Keys

- [ ] Register for AccuWeather account: https://developer.accuweather.com/
- [ ] Create AccuWeather app and copy API key
- [ ] Register for WeatherAPI.com account: https://www.weatherapi.com/
- [ ] Copy WeatherAPI.com key from dashboard
- [ ] Save both keys securely

### ✅ Step 2: Verify Current System

```bash
# Check current Supabase connection
supabase status

# List current functions
supabase functions list

# Check current secrets
supabase secrets list
```

---

## Deployment Steps

### ✅ Step 3: Deploy Database Migrations

```bash
# Deploy weather cache and API tracking tables
supabase db push

# Or apply specific migrations
cd supabase/migrations
# Ensure these files exist:
# - 20250203120000_create_weather_cache.sql
# - 20250203120001_setup_weather_cron.sql
```

**Verify migration success:**
```sql
-- Run in Supabase SQL Editor
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN ('weather_cache', 'weather_api_usage');

-- Should return both tables
```

### ✅ Step 4: Set API Keys as Secrets

```bash
# Set AccuWeather key
supabase secrets set ACCUWEATHER_API_KEY=your_actual_accuweather_key

# Set WeatherAPI.com key
supabase secrets set WEATHERAPI_KEY=your_actual_weatherapi_key

# Verify secrets are set
supabase secrets list
```

**Expected output:**
```
ACCUWEATHER_API_KEY
WEATHERAPI_KEY
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
```

### ✅ Step 5: Deploy Edge Functions

```bash
# Deploy the new update-weather-cache function
supabase functions deploy update-weather-cache

# Redeploy enhanced-weather-alert with cache integration
supabase functions deploy enhanced-weather-alert

# Verify deployment
supabase functions list
```

**Expected functions:**
- `update-weather-cache` (new)
- `enhanced-weather-alert` (updated)
- All other existing functions

### ✅ Step 6: Test AccuWeather API

```bash
# Test AccuWeather location key retrieval
curl "http://dataservice.accuweather.com/locations/v1/cities/geoposition/search?apikey=YOUR_KEY&q=14.262585,121.398436"

# Should return location key for LSPU Santa Cruz area
```

### ✅ Step 7: Test WeatherAPI.com

```bash
# Test WeatherAPI.com current weather
curl "https://api.weatherapi.com/v1/current.json?key=YOUR_KEY&q=14.262585,121.398436&aqi=yes"

# Should return current weather data with Air Quality
```

### ✅ Step 8: Initialize Weather Cache

**Option A: Using curl**
```bash
curl -X POST https://hmolyqzbvxxliemclrld.supabase.co/functions/v1/update-weather-cache \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"location": "LSPU"}'
```

**Option B: Using Supabase SQL Editor**
```sql
SELECT net.http_post(
  url := 'https://hmolyqzbvxxliemclrld.supabase.co/functions/v1/update-weather-cache',
  headers := jsonb_build_object(
    'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhtb2x5cXpidnh4bGllbWNscmxkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDI0Njk3MCwiZXhwIjoyMDc1ODIyOTcwfQ.496txRbAGuiOov76vxdwSDUHplBt1osOD2PyV0EE958',
    'Content-Type', 'application/json'
  ),
  body := '{"location": "LSPU"}'::jsonb
);
```

### ✅ Step 9: Verify Cache Population

```sql
-- Run in Supabase SQL Editor
SELECT 
  location_name,
  temperature,
  weather_text,
  data_source,
  last_updated,
  AGE(NOW(), last_updated) as cache_age
FROM weather_cache;
```

**Expected result:**
- Location: LSPU Santa Cruz Main Campus
- Temperature: Current temp in °C
- Data source: 'accuweather' or 'weatherapi'
- Last updated: Recent timestamp

### ✅ Step 10: Verify Cron Job

```sql
-- Check cron job is scheduled
SELECT 
  jobid,
  jobname,
  schedule,
  active
FROM cron.job 
WHERE jobname = 'update-weather-cache-every-2hrs';
```

**Expected result:**
- jobname: update-weather-cache-every-2hrs
- schedule: 0 */2 * * *
- active: true

### ✅ Step 11: Test Frontend Integration

**Test user.html:**
1. Open: https://your-domain/user.html
2. Check weather dashboard displays
3. Verify temperature, humidity, wind data shows
4. Check "Last updated" timestamp

**Test early-warning-dashboard.html:**
1. Open admin dashboard
2. Check weather section
3. Verify all weather metrics display
4. Check alerts are generated

### ✅ Step 12: Monitor API Usage

```sql
-- Check API calls made today
SELECT 
  api_provider,
  COUNT(*) as requests,
  SUM(calls_count) as total_api_calls,
  COUNT(*) FILTER (WHERE success = false) as failures
FROM weather_api_usage
WHERE created_at >= CURRENT_DATE
GROUP BY api_provider;
```

**Expected after 1 day:**
- AccuWeather: 12 requests, ~24 API calls
- WeatherAPI: 0 requests (unless fallback triggered)
- Failures: 0

---

## Post-Deployment Verification

### ✅ Step 13: 24-Hour Monitoring

Monitor the system for 24 hours:

**Morning check (9 AM):**
```sql
SELECT * FROM weather_cache ORDER BY last_updated DESC LIMIT 1;
SELECT COUNT(*) FROM weather_api_usage WHERE created_at >= CURRENT_DATE;
```

**Evening check (9 PM):**
```sql
-- Should show ~10-12 cache updates
SELECT 
  api_provider,
  COUNT(*),
  SUM(calls_count) as api_calls
FROM weather_api_usage 
WHERE created_at >= CURRENT_DATE
GROUP BY api_provider;
```

### ✅ Step 14: Test Fallback Mechanism

**Temporarily disable AccuWeather:**
```bash
# Set invalid key to test fallback
supabase secrets set ACCUWEATHER_API_KEY=invalid_key_for_testing
```

**Trigger update:**
```bash
curl -X POST https://hmolyqzbvxxliemclrld.supabase.co/functions/v1/update-weather-cache \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"location": "LSPU"}'
```

**Verify fallback:**
```sql
-- Should show 'weatherapi' as data_source
SELECT data_source, last_updated FROM weather_cache;
```

**Restore AccuWeather key:**
```bash
supabase secrets set ACCUWEATHER_API_KEY=your_actual_key
```

### ✅ Step 15: Check Function Logs

```bash
# Monitor update-weather-cache logs
supabase functions logs update-weather-cache --tail

# Monitor enhanced-weather-alert logs
supabase functions logs enhanced-weather-alert --tail
```

**Look for:**
- ✅ "AccuWeather data fetched successfully"
- ✅ "Weather cache updated successfully"
- ❌ No error messages

---

## Rollback Plan (If Issues Occur)

### Emergency Rollback Steps

**1. Revert to OpenWeatherMap (if needed):**

```bash
# The old OpenWeatherMap key might still work
supabase secrets list

# Enhanced-weather-alert can temporarily use old API
# (Keep the migration, just fix the function code if needed)
```

**2. Disable cron job:**
```sql
-- Temporarily disable automatic updates
SELECT cron.unschedule('update-weather-cache-every-2hrs');
```

**3. Manual cache updates:**
```bash
# Update manually until issue is resolved
curl -X POST https://hmolyqzbvxxliemclrld.supabase.co/functions/v1/update-weather-cache \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"location": "LSPU"}'
```

**4. Re-enable cron after fix:**
```sql
-- Re-schedule updates
SELECT cron.schedule(
  'update-weather-cache-every-2hrs',
  '0 */2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://hmolyqzbvxxliemclrld.supabase.co/functions/v1/update-weather-cache',
    headers := jsonb_build_object(
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhtb2x5cXpidnh4bGllbWNscmxkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDI0Njk3MCwiZXhwIjoyMDc1ODIyOTcwfQ.496txRbAGuiOov76vxdwSDUHplBt1osOD2PyV0EE958',
      'Content-Type', 'application/json'
    ),
    body := '{"location": "LSPU"}'::jsonb
  );
  $$
);
```

---

## Success Criteria

✅ Weather cache updates every 2 hours  
✅ AccuWeather API calls < 30/day  
✅ Zero frontend errors  
✅ Weather data displays correctly  
✅ Automatic fallback to WeatherAPI works  
✅ Air Quality data available (from WeatherAPI)  
✅ Weather alerts generated correctly  
✅ No rate limit errors  

---

## Maintenance Schedule

### Daily
- [ ] Check API usage (should be ~24 calls/day)
- [ ] Verify cache is updating

### Weekly
- [ ] Review error logs
- [ ] Check fallback frequency
- [ ] Verify data accuracy

### Monthly
- [ ] Review API costs (should be ₱0)
- [ ] Check cron job performance
- [ ] Verify both API keys are valid

---

## Contact & Support

**Documentation:**
- Setup Guide: `WEATHER_API_SETUP.md`
- This Checklist: `WEATHER_API_DEPLOYMENT_CHECKLIST.md`

**Monitoring Queries:**
```sql
-- Quick health check
SELECT 
  'Cache Status' as check_type,
  location_name,
  data_source,
  AGE(NOW(), last_updated) as age
FROM weather_cache

UNION ALL

SELECT 
  'API Usage Today',
  api_provider,
  SUM(calls_count)::text,
  NULL
FROM weather_api_usage 
WHERE created_at >= CURRENT_DATE
GROUP BY api_provider;
```

---

## ✅ Deployment Complete!

Once all steps are checked off, the new weather system is live:

🌤️ **AccuWeather primary** (high accuracy)  
☁️ **WeatherAPI.com fallback** (includes AQI)  
💾 **Database caching** (unlimited users)  
⏰ **Automatic updates** (every 2 hours)  
💰 **Cost**: ₱0/month  

**Next steps:** Monitor for 24-48 hours to ensure stability.

