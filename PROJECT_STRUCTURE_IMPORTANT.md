# ⚠️ IMPORTANT: Project Structure

## The REAL Working Project Location

**Always work in:** `C:\Users\Ducay\Desktop\lspu_dres\lspu_dres\mobile_app\`

### Why?

You have a duplicate folder structure:
- ❌ `C:\Users\Ducay\Desktop\lspu_dres\mobile_app\` - OLD/BROKEN version
- ✅ `C:\Users\Ducay\Desktop\lspu_dres\lspu_dres\mobile_app\` - WORKING version with weather & notifications

### Evidence:

1. ✅ The nested version has the working APK builds
2. ✅ No compilation errors (only minor warnings)
3. ✅ Weather system works correctly  
4. ✅ OneSignal notifications work correctly
5. ✅ Last successful build: December 4, 2025

### To Build APK:

```powershell
cd C:\Users\Ducay\Desktop\lspu_dres\lspu_dres\mobile_app
flutter build apk --release
```

### APK Location:

`lspu_dres\mobile_app\build\app\outputs\flutter-apk\app-release.apk`

### TODO: Clean Up (when files aren't in use)

1. Close all files in Cursor IDE
2. Delete `C:\Users\Ducay\Desktop\lspu_dres\mobile_app\` (the root duplicate)
3. Move `lspu_dres\lspu_dres\mobile_app` to `lspu_dres\mobile_app`
4. Update git tracking

---

**Date:** December 4, 2025  
**Build Status:** ✅ WORKING (63.6MB APK built successfully)

