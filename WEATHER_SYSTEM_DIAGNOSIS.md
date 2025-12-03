# Weather System Diagnosis & Fix

## 🔍 Current State Analysis

Based on error logs and code review, here's what I found:

### What's in GitHub Repo (Your Local Code)

**All HTML files have CORRECT coordinates:**
- `public/early-warning-dashboard.html` → 14.262585, 121.398436 ✅
- `public/user.html` → 14.262585, 121.398436 ✅
- `public/super-user-early-warning.html` → 14.262585, 121.398436 ✅
- `mobile_app/lib/screens/home_screen.dart` → 14.262585, 121.398436 ✅

**Functions deployed:**
- ✅ `enhanced-weather-alert` with proximity search
- ✅ `update-weather-cache` with hybrid strategy
- ✅ API integrations (_shared/accuweather.ts, _shared/weatherapi.ts)

### What's Actually Running (Based on Logs)

**Error logs show:**
```
Looking for weather cache at (14.2206, 121.312)  ← OLD COORDS!
Looking for weather cache at (14.26284, 121.39743)  ← OLD COORDS!
```

**This means:**
- Your LIVE website (Cloudflare Workers) is serving OLD HTML files
- Your mobile phone has OLD APK installed
- The database cache has CORRECT coordinates (14.262585, 121.398436)
- Result: Coordinate mismatch = weather doesn't load

### Database Status

**Cache entry:**
- Location: LSPU Santa Cruz Main Campus
- Coordinates: 14.26258500, 121.39843600 (8 decimal precision in DB)
- Data source: hybrid:accuweather+weatherapi
- Has hourly forecast: true
- Has air quality: true  
- Temperature: ~25°C

## 🎯 Root Cause

**The disconnect:**
```
GitHub Repo Files → Correct coordinates (14.262585, 121.398436)
           ↓
    [NOT DEPLOYED]
           ↓
Live Cloudflare → OLD HTML with wrong coordinates
Live Mobile APK → OLD APK with wrong coordinates
           ↓
    Enhanced-weather-alert → Can't find cache
           ↓
        500 Error
```

## 🔧 Complete Fix

### Step 1: Verify Database Has Weather Cache

Run in Supabase SQL Editor:

```sql
-- Check if tables exist and have data
SELECT 
  location_name,
  latitude,
  longitude,
  temperature,
  data_source,
  hourly_forecast IS NOT NULL as has_hourly,
  last_updated
FROM weather_cache;
```

**Expected:** Should return 1 row with LSPU data

**If NO rows:** Run this to populate cache:
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

### Step 2: Deploy HTML Files to Cloudflare Workers

Your GitHub has correct files, but Cloudflare Workers is serving old cached versions.

**How to update Cloudflare Workers:**

1. **Option A - Cloudflare Dashboard:**
   - Go to: https://dash.cloudflare.com/
   - Select your Workers project
   - Upload/update HTML files from your `public/` folder
   - Deploy

2. **Option B - Purge Cloudflare Cache:**
   - Cloudflare Dashboard → Caching
   - Click "Purge Everything"
   - Wait 5 minutes
   - Your GitHub repo should auto-deploy

3. **Option C - If you have deployment script:**
   - Run your normal deployment command
   - Example: `wrangler publish` or `npm run deploy`

### Step 3: Install New Mobile APK

**Download from GitHub:**
```
https://github.com/456123qwertasdf-prog/lspu_dres/raw/master/public/lspu-emergency-response.apk
```

**Install on phone:**
1. Uninstall old Kapiyu app
2. Install the new APK
3. Open app and test

## ✅ Verification Steps

After completing fixes:

### Test Web Dashboards

1. Open: `https://dres-lspu-edu-ph.456123qwert-asdf.workers.dev/user`
2. Hard refresh: Ctrl+Shift+R
3. Should see:
   - Temperature: ~25°C
   - Humidity: ~88%
   - Air Quality: number value
   - Hourly forecast cards
   - No 500 errors

### Test Mobile App

1. Open Kapiyu app
2. Pull down to refresh
3. Should see same weather data

### Check Function Logs

https://supabase.com/dashboard/project/hmolyqzbvxxliemclrld/functions/enhanced-weather-alert/logs

Should show:
```
✅ Found weather cache at (14.262585, 121.398436) for request (14.262585, 121.398436)
✅ Using cached weather data from hybrid:accuweather+weatherapi
```

## 📊 What's Working vs Not Working

### ✅ Working (Backend)

- Database: weather_cache table with hybrid data
- Supabase functions: deployed and correct
- API strategy: AccuWeather + WeatherAPI hybrid
- Cron job: scheduled every 2 hours
- API tracking: monitoring calls
- GitHub repo: all files correct

### ❌ Not Working (Frontend Deployment)

- Cloudflare Workers: serving old HTML
- Mobile device: running old APK
- Result: Coordinate mismatch causing 500 errors

## 🎯 Summary

**Your code is perfect! The deployment is the issue.**

**GitHub** ✅ Has correct files  
**Cloudflare** ❌ Needs redeployment  
**Mobile Phone** ❌ Needs new APK installation  

The fix is NOT code changes - it's updating your live deployments to use the GitHub code!

## 📝 Quick Checklist

- [ ] Verify weather_cache table has data (run SQL check)
- [ ] Redeploy HTML to Cloudflare Workers
- [ ] Install new APK on mobile device
- [ ] Test all dashboards
- [ ] Verify no 500 errors
- [ ] Confirm forecast displays
- [ ] Check Air Quality shows data

Once these deployments are done, everything will work perfectly!

