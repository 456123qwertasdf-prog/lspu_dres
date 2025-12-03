# Mobile Earthquake Alert Notification Fix

## Problem Fixed ✅

**Before**: When sending earthquake safety alerts from the mobile app, citizens would only receive notifications if their app was **open**. Notifications were **not sent** to users with their app closed.

**After**: When sending earthquake safety alerts from the mobile app, citizens now receive push notifications **even when the app is closed**, just like when alerts are sent from the web admin.

## What Was Changed

### 1. Mobile App Code Update
**File**: `lspu_dres/mobile_app/lib/screens/super_user_dashboard_screen.dart`

Added automatic call to `announcement-notify` Supabase Edge Function after creating an announcement:

```dart
// Send push notifications to all users
try {
  await SupabaseService.client.functions.invoke(
    'announcement-notify',
    body: {'announcementId': response['id']},
  );
  debugPrint('✅ Push notifications sent for announcement: ${response['id']}');
} catch (notifyError) {
  debugPrint('⚠️ Failed to send push notifications: $notifyError');
  // Don't fail the whole operation if notifications fail
}
```

### 2. Version Update
- Updated from version `1.0.0+1` to `1.1.0+2` in `pubspec.yaml`
- This ensures users know they have the latest version

### 3. Documentation
- Created SQL migration file documenting notification flow
- Added comments for future reference

## How It Works Now

### Flow Diagram

```
Mobile App (Super User)
    ↓
Creates announcement in database
    ↓
Calls announcement-notify edge function
    ↓
announcement-notify function:
  - Creates in-app notifications
  - Calls onesignal-send function
    ↓
onesignal-send sends push notifications
    ↓
OneSignal delivers to ALL devices
    ↓
Citizens receive alert (even if app closed)
```

### Previous Flow (Broken)

```
Mobile App
    ↓
Creates announcement in database
    ↓
❌ STOPPED HERE - No notifications sent
    ↓
Only users who opened the app would see it via sync
```

## Testing Instructions

### Prerequisites
1. **Install the new APK** (version 1.1.0+2)
   - Download from: `https://github.com/456123qwertasdf-prog/lspu_dres/raw/master/public/lspu-emergency-response.apk`
   - Or from your project root: `app-release-NOTIFICATION-FIX-20251204-063429.apk`

2. **You need at least 2 devices:**
   - **Device A**: Super user or admin account (sender)
   - **Device B**: Citizen account (receiver)

3. **Both devices must:**
   - Have the new APK version (1.1.0+2) installed
   - Have notification permissions granted
   - Be logged in at least once (to register OneSignal player ID)

### Test Procedure

#### Test 1: Earthquake Alert with App Closed ✅

1. **On Device B (Citizen)**:
   - Open the app and log in
   - Grant notification permissions if prompted
   - Navigate to Profile and verify OneSignal player ID is synced
   - **CLOSE the app completely** (swipe away from recent apps)
   - Lock the phone

2. **On Device A (Super User)**:
   - Open the app and log in as super user or admin
   - Go to the "Home" tab
   - Scroll down to "Quick Emergency Alerts" section
   - Tap **"Earthquake Safety Alert"**
   - Confirm "Send alert to all users?"
   - Wait for success message: "✅ Alert sent to all users!"

3. **On Device B (Citizen)**:
   - Should receive push notification **IMMEDIATELY**
   - Even though app was closed
   - Notification should show:
     - Title: "🚨 Earthquake Safety Alert"
     - Message: "⚠️ EARTHQUAKE ALERT: If you feel strong shaking, DROP, COVER, and HOLD ON..."
   - Tapping notification should open the app

#### Test 2: Fire Alert with App Closed ✅

1. **On Device B (Citizen)**:
   - Keep app closed

2. **On Device A (Super User)**:
   - Tap **"Fire Emergency Alert"**
   - Confirm sending

3. **On Device B (Citizen)**:
   - Should receive: "🚨 Fire Emergency Alert"
   - Message: "🔥 FIRE EMERGENCY: A fire-related hazard..."

#### Test 3: Verify from Web Admin Still Works ✅

1. **From Web Browser** (as admin):
   - Go to `announcements.html`
   - Create a new emergency announcement
   - Send it

2. **On Device B (Citizen)**:
   - Should still receive notification with app closed
   - This confirms web admin functionality wasn't broken

#### Test 4: Multiple Citizens Receive ✅

1. Have multiple citizen devices with app closed
2. Send one earthquake alert from mobile
3. Verify ALL citizens receive the notification

### Expected Results

✅ **Should Work**:
- Push notifications sent to all users
- Works when app is closed
- Works when app is in background
- Works when app is in foreground
- Same behavior as web admin alerts
- Emergency sound plays (if custom sound configured)
- Notification appears on lock screen
- Tapping notification opens app

❌ **Common Issues**:

| Issue | Solution |
|-------|----------|
| No notification received | Check OneSignal player ID is registered (Profile screen) |
| "Failed to send push notifications" error | Check Supabase Edge Functions are deployed |
| Notification received but no sound | Check notification permissions and Android Do Not Disturb settings |
| Old version behavior | Uninstall old app completely, install new APK (v1.1.0+2) |

## Verification Checklist

Before marking as complete, verify:

- [ ] New APK version is 1.1.0+2
- [ ] Mobile earthquake alert sends push notifications to closed apps
- [ ] Mobile fire alert sends push notifications to closed apps
- [ ] Web admin alerts still work
- [ ] Multiple citizens receive notifications
- [ ] Notifications work on lock screen
- [ ] Tapping notification opens app
- [ ] Emergency sound plays (if configured)
- [ ] No error messages in Supabase logs

## Troubleshooting

### Check Supabase Logs

1. Go to Supabase Dashboard
2. Navigate to **Edge Functions** > **Logs**
3. Look for logs from `announcement-notify` and `onesignal-send`
4. Should see:
   ```
   ✅ OneSignal notifications sent: X devices
   ```

### Check OneSignal Delivery

1. Go to OneSignal Dashboard
2. Navigate to **Messages** > **Delivery**
3. Should see recent notifications
4. Check delivery statistics

### Debug Mobile App

1. Connect device via USB
2. Run: `flutter logs`
3. Send alert from mobile
4. Look for:
   ```
   ✅ Push notifications sent for announcement: <id>
   ```
4. If you see error: Check Supabase Edge Function deployment

## Files Changed

1. `lspu_dres/mobile_app/lib/screens/super_user_dashboard_screen.dart`
   - Added call to announcement-notify function

2. `lspu_dres/mobile_app/pubspec.yaml`
   - Updated version from 1.0.0+1 to 1.1.0+2

3. `supabase/migrations/20251204_auto_notify_announcements.sql`
   - Documentation for notification flow

4. `public/lspu-emergency-response.apk`
   - Updated APK with fix (63.6 MB)

## Deployment Status

✅ **Completed**:
- [x] Code changes made
- [x] Version number updated
- [x] APK rebuilt
- [x] APK copied to public folder
- [x] Changes pushed to GitHub
- [x] Documentation created

⏳ **Pending**:
- [ ] User testing and verification
- [ ] Deploy SQL migration to Supabase (if using webhook option)

## Additional Notes

### Why This Fix Works

The web admin has always been calling `announcement-notify` function, which is why it worked. The mobile app was only inserting into the database without calling the notification function. Now both web and mobile follow the same flow.

### Future Improvements

For even more reliability, you could set up a **Database Webhook** in Supabase:

1. Go to Supabase Dashboard > Database > Webhooks
2. Create webhook for `announcements` table
3. Event: INSERT
4. URL: `https://your-project.supabase.co/functions/v1/announcement-notify`
5. Body: `{"announcementId": "{{ record.id }}"}`

This would ensure notifications are sent even if the mobile app fails to call the function.

## Support

If you encounter any issues:
1. Check this guide's troubleshooting section
2. Review Supabase Edge Function logs
3. Check OneSignal delivery logs
4. Verify device OneSignal player ID is registered
5. Ensure notification permissions are granted

---

**Version**: 1.1.0+2  
**Date**: December 4, 2025  
**Status**: ✅ Ready for Testing

