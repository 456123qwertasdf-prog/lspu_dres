# OneSignal Player ID Login Fix

## 🐛 Problem Description

**Issue:** When a user logs in for the first time, the OneSignal Player ID is not saved to Supabase. However, after quitting and reopening the app (while staying logged in), the Player ID gets saved successfully.

## 🔍 Root Cause

The issue occurs due to a **timing problem** in the app initialization flow:

1. **App Starts** → `main.dart` calls `OneSignalService().initialize()`
2. **OneSignal SDK** initializes and generates a Player ID
3. **Attempts to Save** → Calls `_savePlayerIdToSupabase(playerId)`
4. **❌ FAILS** → `SupabaseService.currentUserId` is `null` because user hasn't logged in yet
5. **Save Silently Fails** → Code exits early at line 89-92 in `onesignal_service.dart`
6. **User Logs In** → No retry mechanism to save the Player ID
7. **Player ID Not Saved** → Notifications fail because database has no Player ID
8. **User Quits & Reopens** → OneSignal initializes again, user is already logged in → Save succeeds ✅

### Code Flow Diagram

```
App Start → OneSignal.initialize() → Get Player ID
                                            ↓
                                    Try to save to Supabase
                                            ↓
                               userId = null (not logged in yet)
                                            ↓
                                      ❌ SAVE FAILS
                                            ↓
                                    User logs in later
                                            ↓
                              NO RETRY MECHANISM ⚠️
                                            ↓
                          Player ID remains unsaved in database
```

## ✅ The Fix

Added a **retry mechanism** to save the Player ID immediately after successful login.

### Changes Made

#### 1. Added `retrySavePlayerIdToSupabase()` method in `onesignal_service.dart`

```dart
/// Retry saving player ID to Supabase (call this after login)
Future<void> retrySavePlayerIdToSupabase() async {
  if (_playerId != null && _playerId!.isNotEmpty) {
    debugPrint('🔄 Retrying to save OneSignal Player ID after login...');
    await _savePlayerIdToSupabase(_playerId!);
  } else {
    debugPrint('⚠️ Cannot retry: Player ID not available yet');
    // Try to get it again
    final currentId = OneSignal.User.pushSubscription.id;
    if (currentId != null && currentId.isNotEmpty) {
      _playerId = currentId;
      debugPrint('🔄 Found Player ID, saving now: $_playerId');
      await _savePlayerIdToSupabase(_playerId!);
    }
  }
}
```

#### 2. Updated `login_screen.dart` to call retry after login

- Added import: `import '../services/onesignal_service.dart';`
- Added retry call in `_handleLogin()` method after successful login:

```dart
// Retry saving OneSignal player ID after successful login
debugPrint('✅ Login successful, retrying OneSignal Player ID save...');
await OneSignalService().retrySavePlayerIdToSupabase();
```

### New Flow After Fix

```
App Start → OneSignal.initialize() → Get Player ID
                                            ↓
                                    Try to save to Supabase
                                            ↓
                               userId = null (not logged in yet)
                                            ↓
                                      ❌ SAVE FAILS
                                            ↓
                                    User logs in
                                            ↓
                          ✅ RETRY: retrySavePlayerIdToSupabase()
                                            ↓
                        userId now available → Save succeeds!
                                            ↓
                          ✅ Player ID saved to database
```

## 📋 Testing Instructions

### Test Case 1: Fresh Install (First Time Login)

1. **Uninstall** the app completely from the device
2. **Rebuild and Install** the new version with the fix
3. **Open the app** → Login with test credentials
4. **Check Logs** → Should see:
   ```
   ✅ Login successful, retrying OneSignal Player ID save...
   🔄 Retrying to save OneSignal Player ID after login...
   💾 Saving OneSignal Player ID to Supabase: [player_id] for user: [user_id]
   ✅ OneSignal Player ID saved to Supabase: [player_id]
   ```
5. **Verify in Database:**
   ```sql
   SELECT id, email, onesignal_player_id 
   FROM users 
   WHERE email = 'your-test-email@example.com';
   ```
   - `onesignal_player_id` should NOT be null

### Test Case 2: Send Test Notification

After confirming the Player ID is saved:

1. Go to **Supabase Dashboard** → SQL Editor
2. Test a notification (for responder assignments):
   ```sql
   -- Get a test report ID
   SELECT id FROM reports LIMIT 1;
   
   -- Manually trigger assignment notification
   -- (Or create an assignment through the super user dashboard)
   ```
3. **Check device** → Notification should arrive immediately

### Test Case 3: Already Logged In User

1. **Quit the app** (don't log out)
2. **Reopen the app** → Should stay logged in
3. **Check Logs** → OneSignal should initialize with existing Player ID
4. Player ID should remain saved (no changes needed)

## 🔧 Files Modified

1. `mobile_app/lib/services/onesignal_service.dart`
   - Added `retrySavePlayerIdToSupabase()` public method

2. `mobile_app/lib/screens/login_screen.dart`
   - Added import for `OneSignalService`
   - Added retry call after successful login

## 📝 Debug Logs to Watch For

### Successful Flow:
```
OneSignal Player ID (initial): f2c1234a-5678-90ab-cdef-1234567890ab
⚠️ Cannot save OneSignal Player ID: User not authenticated
✅ Login successful, retrying OneSignal Player ID save...
🔄 Retrying to save OneSignal Player ID after login...
💾 Saving OneSignal Player ID to Supabase: f2c1234a-5678-90ab-cdef-1234567890ab for user: abc123...
✅ OneSignal Player ID saved to Supabase: f2c1234a-5678-90ab-cdef-1234567890ab
```

### If Player ID Not Ready Yet:
```
⚠️ Cannot retry: Player ID not available yet
🔄 Found Player ID, saving now: f2c1234a-5678-90ab-cdef-1234567890ab
💾 Saving OneSignal Player ID to Supabase: f2c1234a-5678-90ab-cdef-1234567890ab for user: abc123...
✅ OneSignal Player ID saved to Supabase: f2c1234a-5678-90ab-cdef-1234567890ab
```

## 🚀 Next Steps

1. **Rebuild the mobile app** with these changes
2. **Test with a fresh install** (uninstall first)
3. **Verify Player ID is saved** immediately after login
4. **Test notifications** to confirm they're received

## ✅ Expected Results

- ✅ Player ID saves to database **immediately after login**
- ✅ No need to quit and reopen the app
- ✅ Notifications work right away after first login
- ✅ No more "No OneSignal player ID found" warnings

## 📚 Related Files

- `mobile_app/lib/services/onesignal_service.dart` - OneSignal service with retry logic
- `mobile_app/lib/screens/login_screen.dart` - Login screen with retry call
- `mobile_app/lib/main.dart` - App initialization (OneSignal initializes here)
- `supabase/functions/notify-responder-assignment/index.ts` - Edge function that uses Player ID

---

**Fix Applied:** December 3, 2025
**Status:** ✅ Ready for Testing

