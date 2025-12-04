# 📱 Mobile App Deployment Checklist

## ✅ Pre-Deployment Verification

### 1. Code Changes
- [x] Updated `report_detail_edit_screen.dart` to call Edge Function
- [x] No linter errors in Dart code
- [x] Code follows Flutter best practices
- [x] Debug logging added for troubleshooting

### 2. Edge Functions
- [ ] Verify `assign-responder` is deployed (v9+)
- [ ] Verify `notify-responder-assignment` is deployed (v10+)
- [ ] Test Edge Functions manually via Supabase Dashboard
- [ ] Check Edge Function logs for errors

### 3. Database
- [ ] Verify `onesignal_subscriptions` table exists
- [ ] Verify responders have registered devices
- [ ] Verify super users have mobile access
- [ ] Test SQL queries from `test_mobile_app_notification.sql`

### 4. OneSignal Configuration
- [ ] Verify OneSignal App ID is correct
- [ ] Verify OneSignal REST API Key is set in Edge Function secrets
- [ ] Test OneSignal API manually (optional)
- [ ] Verify mobile app has correct OneSignal SDK integration

---

## 🧪 Testing Checklist

### Test 1: Basic Assignment (Normal Priority)
- [ ] Log into mobile app as super user
- [ ] Navigate to Reports tab
- [ ] Select an unassigned report (priority 3-4)
- [ ] Tap Edit button
- [ ] Select a responder who has OneSignal player ID
- [ ] Tap Save Changes
- [ ] Verify success message shown
- [ ] Check responder's device for push notification
- [ ] Verify notification appears in responder's app
- [ ] Check `assign-responder` Edge Function logs
- [ ] Check `notify-responder-assignment` Edge Function logs
- [ ] Verify database records created

### Test 2: Critical Assignment (High Priority)
- [ ] Select an unassigned critical report (priority ≤ 2)
- [ ] Assign to responder via mobile app
- [ ] Verify responder receives CRITICAL notification (red, emergency sound)
- [ ] Verify notification priority is correct
- [ ] Check Edge Function logs

### Test 3: Reassignment
- [ ] Select a report that already has a responder
- [ ] Change to a different responder
- [ ] Verify old assignment is cancelled
- [ ] Verify new assignment is created
- [ ] Verify new responder receives notification
- [ ] Verify old responder does NOT receive notification

### Test 4: Unassignment
- [ ] Select a report with an assigned responder
- [ ] Clear the responder selection (set to null)
- [ ] Save changes
- [ ] Verify assignment is cancelled in database
- [ ] Verify report responder_id is cleared

### Test 5: Multiple Devices
- [ ] Find a responder with multiple devices registered
- [ ] Assign a report to them
- [ ] Verify ALL devices receive the notification
- [ ] Check Edge Function logs for multiple device sends

### Test 6: Error Handling
- [ ] Try assigning with no internet connection
- [ ] Verify appropriate error message shown
- [ ] Try assigning to non-existent responder (shouldn't be possible)
- [ ] Verify app doesn't crash on errors

---

## 📊 Database Verification Queries

Run these queries in Supabase SQL Editor after testing:

### Check Assignment Created
```sql
SELECT * FROM assignment 
WHERE report_id = 'YOUR_TEST_REPORT_ID'
ORDER BY assigned_at DESC 
LIMIT 1;
```

### Check Notification Created
```sql
SELECT * FROM notifications 
WHERE payload->>'report_id' = 'YOUR_TEST_REPORT_ID'
  AND type = 'assignment_created'
ORDER BY created_at DESC 
LIMIT 1;
```

### Check Responder Has Devices
```sql
SELECT * FROM onesignal_subscriptions 
WHERE user_id = (
  SELECT user_id FROM responder 
  WHERE id = 'YOUR_TEST_RESPONDER_ID'
);
```

---

## 🚀 Build & Deploy

### Android Build
```bash
cd lspu_dres/mobile_app

# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Or build App Bundle for Play Store
flutter build appbundle --release
```

**Output:**
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Bundle: `build/app/outputs/bundle/release/app-release.aab`

### iOS Build
```bash
cd lspu_dres/mobile_app

# Clean build
flutter clean
flutter pub get

# Build release iOS
flutter build ios --release

# Open Xcode to archive and upload
open ios/Runner.xcworkspace
```

**Steps in Xcode:**
1. Select "Any iOS Device" as target
2. Product → Archive
3. Distribute App → App Store Connect
4. Upload

---

## 📱 Distribution

### Option 1: Google Play Store (Android)
1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Create new release (Production or Internal Testing)
4. Upload `app-release.aab`
5. Add release notes mentioning notification fix
6. Review and roll out

### Option 2: Apple App Store (iOS)
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Create new version
4. Upload build from Xcode
5. Add release notes mentioning notification fix
6. Submit for review

### Option 3: Direct APK Distribution (Android)
1. Upload `app-release.apk` to your server
2. Share download link with users
3. Users must enable "Install from Unknown Sources"
4. Users download and install APK

---

## 📝 Release Notes Template

```
Version: X.X.X
Release Date: December 4, 2025

🔔 NEW FEATURES:
- Mobile super users can now send notifications to responders when assigning reports
- Push notifications are sent immediately when assignments are made
- Responders receive real-time alerts on their devices

✅ IMPROVEMENTS:
- Consistent notification behavior between web and mobile interfaces
- Better error handling for assignment operations
- Enhanced logging for troubleshooting

🐛 BUG FIXES:
- Fixed issue where mobile assignments didn't send notifications
- Fixed responder assignment flow to use Edge Functions

🔧 TECHNICAL:
- Updated report assignment logic to call assign-responder Edge Function
- Integrated with notify-responder-assignment notification system
- Added support for critical and normal priority notifications
```

---

## ✅ Post-Deployment Verification

### Immediate Checks (Within 1 hour)
- [ ] Monitor Edge Function logs for errors
- [ ] Check for crash reports in Firebase/Sentry
- [ ] Verify at least one successful assignment from mobile app
- [ ] Confirm responder received notification

### Daily Checks (First 3 days)
- [ ] Monitor notification delivery rate
- [ ] Check for user-reported issues
- [ ] Review Edge Function performance metrics
- [ ] Verify database records are correct

### Weekly Checks
- [ ] Review notification analytics
- [ ] Check responder response times
- [ ] Analyze assignment patterns
- [ ] Gather user feedback

---

## 🐛 Rollback Plan

If critical issues are found:

### Quick Fix (Minor Issues)
1. Identify the issue in Edge Function logs
2. Fix the Edge Function code
3. Redeploy Edge Function
4. No mobile app update needed

### Full Rollback (Major Issues)
1. Revert to previous mobile app version
2. Notify users to update
3. Investigate issue in development
4. Fix and re-test thoroughly
5. Deploy fixed version

### Emergency Workaround
If notifications are broken but assignments work:
1. Users can still assign via mobile app
2. Responders can check dashboard manually
3. Use web interface for critical assignments
4. Fix and deploy update ASAP

---

## 📞 Support Contacts

### Technical Issues
- **Edge Functions:** Check Supabase Dashboard logs
- **Mobile App:** Check device logs / Firebase Crashlytics
- **OneSignal:** Check OneSignal Dashboard

### User Support
- Provide instructions for enabling notifications
- Guide users to check notification permissions
- Explain how to verify OneSignal registration

---

## 📊 Success Metrics

Track these metrics after deployment:

- **Notification Delivery Rate:** Target 95%+
- **Assignment Success Rate:** Target 99%+
- **Average Notification Delay:** Target < 5 seconds
- **Responder Response Time:** Expected to improve
- **User Satisfaction:** Gather feedback

---

## 🎯 Deployment Decision

### Ready to Deploy When:
- [x] All code changes complete
- [x] No linter errors
- [ ] All tests passed
- [ ] Edge Functions verified deployed
- [ ] Database verified working
- [ ] Documentation complete
- [ ] Rollback plan prepared

### Deploy To:
- [ ] Internal Testing (recommended first)
- [ ] Beta Users
- [ ] Production

---

## 📚 Documentation References

- [MOBILE_APP_NOTIFICATION_FIX.md](./MOBILE_APP_NOTIFICATION_FIX.md) - Complete fix details
- [MOBILE_NOTIFICATION_SUMMARY.md](./MOBILE_NOTIFICATION_SUMMARY.md) - Quick summary
- [MOBILE_NOTIFICATION_FLOW.md](./MOBILE_NOTIFICATION_FLOW.md) - System flow diagrams
- [test_mobile_app_notification.sql](./test_mobile_app_notification.sql) - Test queries
- [NOTIFICATION_SYSTEM_STATUS.md](./NOTIFICATION_SYSTEM_STATUS.md) - Overall system status

---

**Deployment Status:** 🟡 READY FOR TESTING  
**Next Step:** Complete testing checklist  
**Target Deployment:** After successful testing  

**Last Updated:** December 4, 2025

