# Fix: Earthquake Safety Alerts Not Showing on Mobile

## Problem Identified

When sending earthquake safety alerts (or any emergency alerts), users were not receiving alerts on their mobile devices, even though notifications were working on the web.

### Root Causes

1. **Channel ID Mismatch**: 
   - Backend was sending notifications with channel ID: `62b67b1a-b2c2-4073-92c5-3b1d416a4720`
   - Android app was creating a channel with ID: `emergency_alerts`
   - When Android receives a notification for a channel that doesn't exist, it either drops it or shows it without proper sound/alert behavior

2. **Missing Notification Permission**:
   - Android 13+ (API level 33+) requires explicit `POST_NOTIFICATIONS` permission
   - This permission was not declared in the AndroidManifest.xml

## Changes Made

### 1. Updated MainActivity.kt
**File**: `lspu_dres/mobile_app/android/app/src/main/kotlin/com/example/mobile_app/MainActivity.kt`

Changed the notification channel ID to match the backend:
```kotlin
// BEFORE:
val channelId = "emergency_alerts"

// AFTER:
val channelId = "62b67b1a-b2c2-4073-92c5-3b1d416a4720"
```

This ensures that when OneSignal sends a notification with the channel ID from the backend, Android can find the matching channel on the device.

### 2. Updated AndroidManifest.xml
**File**: `lspu_dres/mobile_app/android/app/src/main/AndroidManifest.xml`

Added the notification permission required for Android 13+:
```xml
<!-- Notification permission for Android 13+ (API level 33+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

## How It Works Now

1. **App Startup**: When the app starts, `MainActivity.onCreate()` creates a notification channel with ID `62b67b1a-b2c2-4073-92c5-3b1d416a4720`
2. **User Login**: OneSignal initializes and requests notification permission (including POST_NOTIFICATIONS on Android 13+)
3. **Alert Sent**: When you send an earthquake safety alert from the web admin:
   - Backend calls the `onesignal-send` function
   - Function sends notification to OneSignal API with `android_channel_id: '62b67b1a-b2c2-4073-92c5-3b1d416a4720'`
   - OneSignal delivers the notification to user devices
   - Android finds the matching channel and displays the notification with:
     - Custom emergency sound (`emergency_alert.mp3`)
     - High priority (shows as heads-up notification)
     - Red color for emergency
     - Vibration enabled
     - Visible on lock screen

## Testing Instructions

### 1. Rebuild the App
```powershell
cd lspu_dres\mobile_app
flutter clean
flutter pub get
flutter build apk --release
```

### 2. Install on Test Device
```powershell
# The APK will be at:
# lspu_dres\mobile_app\build\app\outputs\flutter-apk\app-release.apk

# Install via USB debugging:
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

### 3. Test the Notification
1. **Fresh Install**: Uninstall the old app first if you're testing on a device that already has it
2. **Open App**: Launch the app and log in
3. **Grant Permissions**: Make sure to grant notification permissions when prompted
4. **Send Alert**: From the web admin, create and send an earthquake safety alert
5. **Verify**: 
   - Notification should appear immediately
   - Should play the emergency sound
   - Should show as a heads-up notification (pops up on screen)
   - Should be visible on lock screen

### 4. Troubleshooting

If notifications still don't work:

1. **Check OneSignal Player ID**:
   - Look at the app logs (use `adb logcat` or Android Studio Logcat)
   - Search for "OneSignal Player ID" - it should show a Player ID being saved

2. **Check Device Notification Settings**:
   - Go to Android Settings > Apps > KaPiyu > Notifications
   - Make sure notifications are enabled
   - Check that "Emergency Alerts" channel is enabled

3. **Check Backend Logs**:
   - Go to Supabase dashboard
   - Check the `onesignal-send` function logs
   - Look for the OneSignal API response

4. **Test with OneSignal Dashboard**:
   - Go to OneSignal dashboard (onesignal.com)
   - Navigate to Messages > Send Message
   - Try sending a test notification directly to the Player ID
   - If this works, the issue is in the backend function

## Additional Notes

### Why Channel ID Matters
Android 8.0+ requires notification channels. Each channel has its own settings (sound, vibration, importance). When sending a notification, you must specify which channel to use. If the channel doesn't exist on the device, the notification behavior is undefined.

### OneSignal Channel Management
OneSignal has two types of channels:
1. **Dashboard Channels**: Created in OneSignal dashboard (used for web notifications)
2. **Native Channels**: Created in native Android/iOS code (used for mobile apps)

For mobile apps, you must create the native channel in the app code with the exact same ID that you use in the backend when sending notifications via OneSignal API.

### Emergency Sound File
The emergency sound is located at:
- **Android**: `lspu_dres/mobile_app/android/app/src/main/res/raw/emergency_alert.mp3`
- **Flutter Assets**: `lspu_dres/mobile_app/assets/sounds/emergency_alert.mp3`

The Android version is used by the system for notifications. The Flutter assets version is used when playing sounds from within the app.

## Related Files

- Backend: `supabase/functions/onesignal-send/index.ts`
- Flutter Service: `lspu_dres/mobile_app/lib/services/onesignal_service.dart`
- Android MainActivity: `lspu_dres/mobile_app/android/app/src/main/kotlin/com/example/mobile_app/MainActivity.kt`
- Android Manifest: `lspu_dres/mobile_app/android/app/src/main/AndroidManifest.xml`

