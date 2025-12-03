# Database Revert Instructions for Commit b792623

## Current Status: ✅ Code is Clean at b792623

**Commit:** b792623 - "build: update mobile APK with proximity search and hybrid weather strategy"
**APK Built:** ✅ 63.5MB (located in `mobile_app/build/app/outputs/flutter-apk/app-release.apk`)

## File Status Summary

### ✅ All Emergency SOS Files Removed (Not Present at b792623)
- `supabase/functions/notify-emergency-sos/` - NOT PRESENT ✅
- `supabase/migrations/20250203000001_create_emergency_sos_table.sql` - NOT PRESENT ✅
- `mobile_app/lib/screens/home_screen.dart` - NO EMERGENCY SOS CODE ✅
- All Emergency SOS documentation files - NOT PRESENT ✅

### ✅ All OneSignal Diagnostic Files Removed
- `FIX_SUPER_USER_PUSH_NOTIFICATIONS.md` - NOT PRESENT ✅
- `ONESIGNAL_PLAYER_ID_FIX.md` - NOT PRESENT ✅
- `ONESIGNAL_USER_SWITCHING_FIX.md` - NOT PRESENT ✅
- `fix_super_user_onesignal.sql` - NOT PRESENT ✅
- `debug_onesignal_fetch.sql` - NOT PRESENT ✅
- `check_users_table.sql` - NOT PRESENT ✅

### ✅ OneSignal Service Reverted
- `mobile_app/lib/services/onesignal_service.dart` - AT b792623 VERSION ✅

## Database Objects That May Need Removal

If these were deployed to your Supabase database, run the SQL script to remove them:

### Script: `revert_emergency_sos.sql`

```sql
-- Revert Emergency SOS System
-- This script removes all Emergency SOS related database objects

-- Drop the view first
DROP VIEW IF EXISTS pending_emergency_sos CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS get_active_emergency_sos() CASCADE;
DROP FUNCTION IF EXISTS get_emergency_sos_stats() CASCADE;

-- Drop the table (this will cascade delete all data and indexes)
DROP TABLE IF EXISTS public.emergency_sos CASCADE;

COMMENT ON SCHEMA public IS 'Emergency SOS table and related objects have been removed';
```

### Edge Functions to Remove from Supabase

If deployed, remove this edge function:
- `notify-emergency-sos`

**Command to remove:**
```bash
supabase functions delete notify-emergency-sos
```

## Verification Checklist

Run these queries in Supabase SQL Editor to verify everything is removed:

```sql
-- Check for emergency_sos table
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'emergency_sos'
);
-- Should return: false

-- Check for emergency_sos functions
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%emergency_sos%';
-- Should return: no rows

-- Check for emergency_sos views
SELECT table_name 
FROM information_schema.views 
WHERE table_schema = 'public' 
AND table_name LIKE '%emergency_sos%';
-- Should return: no rows
```

## What's Included at b792623

✅ Proximity-based weather cache lookup
✅ Hybrid weather strategy (AccuWeather current + WeatherAPI forecast)
✅ All reporting features
✅ Assignment system
✅ Announcements
✅ User management
✅ OneSignal notifications (base version, without later fixes)

## What's NOT Included (Removed)

❌ Emergency SOS button
❌ Emergency SOS table and database objects
❌ Emergency SOS notifications
❌ OneSignal diagnostic fixes from later commits

## Next Steps

1. ✅ **Code:** Already at clean commit b792623
2. ✅ **APK:** Already built (63.5MB)
3. ⚠️ **Database:** Run `revert_emergency_sos.sql` in Supabase if Emergency SOS objects exist
4. ⚠️ **Edge Function:** Delete `notify-emergency-sos` function if deployed

## To Deploy This Version

1. Copy the APK to web server:
   ```powershell
   Copy-Item "mobile_app/build/app/outputs/flutter-apk/app-release.apk" "public/lspu-emergency-response.apk"
   ```

2. Clean up database (if needed):
   - Run `revert_emergency_sos.sql` in Supabase SQL Editor

3. Test the app to ensure all features work correctly

## To Return to Master Branch Later

```bash
git checkout master
git stash pop  # This will restore your Emergency SOS removal changes
```

Note: You may want to stay at b792623 if this is your stable version.

