# Notification Deep Linking - Complete Setup

## ✅ What's Been Implemented

When a responder clicks a push notification, the app now **automatically opens the specific report details** instead of just opening the app.

---

## 🔧 Changes Made

### 1. Mobile App Updates

**File: `mobile_app/lib/services/onesignal_service.dart`**
- Added callback functions for notification taps
- Enhanced notification handler to detect assignment vs emergency notifications
- Extracts `report_id` and `assignment_id` from notification data

**File: `mobile_app/lib/main.dart`**
- Added global navigator key for navigation from anywhere
- Set up notification tap handlers
- Automatically fetches and opens report when notification is clicked

### 2. Edge Function (Already Configured)

**File: `supabase/functions/notify-responder-assignment/index.ts`**
- Already sends correct notification data:
  ```javascript
  data: {
    type: 'assignment',
    assignment_id: assignmentId,
    report_id: report.id,
    report_type: report.type,
    priority: report.priority,
    severity: report.severity,
    is_critical: isCritical,
    location: report.location,
    response_time: report.response_time
  }
  ```

---

## 📱 How It Works

### User Flow:

1. **Super User assigns responder** via web interface
2. **Push notification sent** to responder's phone
3. **Responder clicks notification**
4. **App opens automatically** and navigates to report details screen
5. **Full report information displayed** - ready to accept/respond

### Technical Flow:

```
OneSignal Push Received
    ↓
User Taps Notification
    ↓
OneSignal Click Listener Triggered
    ↓
Extract data: { type: 'assignment', report_id: 'xxx', assignment_id: 'yyy' }
    ↓
Callback Function Called
    ↓
Fetch Full Report Data from Supabase
    ↓
Navigate to ReportDetailEditScreen
    ↓
Display Report with Assignment Details
```

---

## 🚀 Deploy the Changes

### Step 1: Rebuild Mobile App

```bash
cd mobile_app

# Clean old build
flutter clean

# Get dependencies
flutter pub get

# Build and install on device
flutter run
# or for release:
flutter build apk
```

### Step 2: Test the Deep Linking

1. **Install rebuilt app** on test device
2. **Log in as Demo Responder**
3. **Keep app in background** (press home button)
4. **Assign Demo Responder** to a report via web
5. **Notification appears** on device
6. **Tap the notification**
7. **App opens to report details** ✅

---

## 📊 What Gets Displayed

When clicking a notification, the responder sees:

### Report Details Screen Shows:
- ✅ Report ID
- ✅ Report Type (Medical, Fire, etc.)
- ✅ Status & Lifecycle Status
- ✅ Assignment Status
- ✅ Location coordinates
- ✅ Description
- ✅ Report image (if available)
- ✅ Created & Updated timestamps
- ✅ **Quick actions**: Accept, En Route, On Scene, Resolve

### Responder Actions Available:
- Accept assignment
- Update status (En Route, On Scene)
- Mark as resolved
- View location on map
- Call for backup

---

## 🎯 Notification Data Structure

### What's Sent in Notification:

```json
{
  "type": "assignment",
  "assignment_id": "abc-123-def-456",
  "report_id": "xyz-789-uvw-012",
  "report_type": "medical",
  "priority": 1,
  "severity": "HIGH",
  "is_critical": true,
  "location": {
    "lat": 14.185,
    "lng": 121.516,
    "address": "LSPU Main Campus"
  },
  "response_time": "5 minutes"
}
```

### How Mobile App Uses It:

1. **Detects**: `type === 'assignment'`
2. **Extracts**: `report_id`
3. **Fetches**: Full report from database
4. **Navigates**: To `ReportDetailEditScreen` with report data

---

## 🔍 Troubleshooting

### Notification Click Doesn't Open Report

**Check:**
1. App is properly rebuilt with new code
2. User is logged in
3. Check debug console for error messages

**Debug logs to look for:**
```
📱 Opening assignment - Report ID: xxx-yyy-zzz
```

If you see this log but no navigation:
- Check if navigator key is properly set
- Verify report exists in database

### App Opens But Shows Wrong Screen

**Possible causes:**
- Navigation state not initialized
- Report data fetch failed

**Fix:** Check that `navigatorKey` is attached to MaterialApp

---

## 💡 Advanced Features (Future Enhancements)

### Possible Additions:

1. **Direct Actions from Notification:**
   ```
   - "Accept" button in notification
   - "Navigate to Location" quick action
   ```

2. **Background Navigation:**
   ```
   - Save navigation intent if app closed
   - Open correct screen on app launch
   ```

3. **Notification Categories:**
   ```
   - Different actions for different emergency types
   - Quick response templates
   ```

---

## 📝 Code Locations

### Notification Handler
- `mobile_app/lib/services/onesignal_service.dart` (lines 140-174)

### Navigation Setup
- `mobile_app/lib/main.dart` (lines 1-77)

### Report Details Screen
- `mobile_app/lib/screens/report_detail_edit_screen.dart`

### Edge Function
- `supabase/functions/notify-responder-assignment/index.ts`

---

## ✅ Summary

**Before:**
- ❌ Click notification → App opens to home screen
- ❌ Responder must search for their assignment
- ❌ Multiple taps needed

**After:**
- ✅ Click notification → Directly to report details
- ✅ Immediate access to all information
- ✅ One tap to see everything
- ✅ Faster response time

---

## 🎉 Result

**Responders can now respond faster because:**
1. No searching needed
2. Immediate context
3. Quick actions available
4. Better user experience

**Test it now by:**
1. Rebuilding the mobile app
2. Assigning Demo Responder
3. Tapping the notification
4. Watching it open directly to the report! 📱✨

---

*Last Updated: December 3, 2025*
*Mobile App Changes: Requires rebuild*
*Edge Function: Already deployed*

