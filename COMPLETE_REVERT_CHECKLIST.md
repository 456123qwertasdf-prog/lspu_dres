# Complete Revert to Commit b792623

**Target Commit:** b792623 - "build: update mobile APK with proximity search and hybrid weather strategy"
**Current Status:** Building from clean commit

## Files to Delete (Added After b792623)

### Emergency SOS Files - ✅ ALREADY DELETED
- [x] `supabase/functions/notify-emergency-sos/index.ts`
- [x] `supabase/migrations/20250203000001_create_emergency_sos_table.sql`
- [x] `EMERGENCY_SOS_SYSTEM.md`
- [x] `EMERGENCY_SOS_DEPLOYMENT.md`
- [x] `EMERGENCY_SOS_SUMMARY.md`
- [x] `test_emergency_sos_notifications.sql`

### OneSignal Fix Files - NEED TO DELETE
- [ ] `FIX_SUPER_USER_PUSH_NOTIFICATIONS.md`
- [ ] `ONESIGNAL_PLAYER_ID_FIX.md`
- [ ] `ONESIGNAL_USER_SWITCHING_FIX.md`
- [ ] `fix_super_user_onesignal.sql`
- [ ] `debug_onesignal_fetch.sql`
- [ ] `check_users_table.sql`

### Modified Files - NEED TO REVERT
- [ ] `mobile_app/lib/services/onesignal_service.dart` - Revert OneSignal changes
- [ ] `mobile_app/lib/screens/home_screen.dart` - Remove Emergency SOS button (in stash)

## Database Objects to Remove

Run `revert_emergency_sos.sql`:
- [ ] Drop `pending_emergency_sos` view
- [ ] Drop `get_active_emergency_sos()` function
- [ ] Drop `get_emergency_sos_stats()` function
- [ ] Drop `emergency_sos` table

## Commits to Revert (8 commits after b792623)

1. cbd737a - Add Emergency SOS button with auto-location detection
2. 6eb191b - Create dedicated Emergency SOS table and system
3. 9d61897 - Add Emergency SOS deployment documentation
4. 09c7c2d - Update APK with emergency_sos table integration
5. 908b585 - Fix notifications schema in notify-emergency-sos function
6. 2ab5e91 - Add Emergency SOS troubleshooting and diagnostic tools
7. 1ec9958 - Fix OneSignal player ID save - removed non-existent users table
8. 4da0fb7 - Fix OneSignal user switching - handles same device multiple accounts

## Actions Completed

✅ Checked out commit b792623 (detached HEAD)
✅ Built clean APK (63.5MB) without Emergency SOS
✅ Stashed home_screen.dart changes

## Next Steps

1. Delete OneSignal diagnostic files
2. Revert onesignal_service.dart to b792623 version
3. Run revert_emergency_sos.sql on database
4. Stay at commit b792623 for deployment
