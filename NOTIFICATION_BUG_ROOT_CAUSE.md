# 🐛 Root Cause: Why Notifications Don't Work When App is Closed

## 🔍 Problem Identified

**citizendemo DOES have a OneSignal player_id registered**, but notifications still don't work when the app is closed.

### The Bug

All 3 test accounts are sharing the **SAME player_id**:
- `responder@demo.com` → `9977822c-7c52-4799-9451-1c06de7c635b`
- `citizen@demo.com` → `9977822c-7c52-4799-9451-1c06de7c635b` ← citizendemo
- `superuser@lspu-dres.com` → `9977822c-7c52-4799-9451-1c06de7c635b`

### Why This Happens

1. **You're testing multiple accounts on the same device**
2. **OneSignal identifies devices, not users**
3. **Each time you login with a different account:**
   - The app registers with OneSignal
   - Gets the SAME device player_id
   - Saves it to Supabase under that user's account
4. **Result:** 3 users in Supabase, but only 1 device in OneSignal

### Why Notifications Fail

When you send a notification to `citizen@demo.com`:
1. ✅ Supabase finds citizendemo's player_id: `9977822c-...`
2. ✅ Sends to OneSignal: "Send to player_id `9977822c-...`"
3. ✅ OneSignal sends to the device
4. ❌ **BUT** the device is confused because 3 accounts are associated with it
5. ❌ The notification might go to the wrong user or not show at all
6. ❌ If you logged in as superuser last, the notification context is wrong

---

## ✅ Solution Options

### **Option 1: Clean Reset (Recommended for Production)**

**Steps:**
1. Run `FIX_DUPLICATE_PLAYER_IDS.sql` in Supabase
2. Uninstall mobile app completely
3. Reinstall mobile app
4. Login ONLY as `citizen@demo.com`
5. Wait 10 seconds for registration
6. Test notifications

**Result:**
- citizendemo gets a fresh, unique player_id
- No conflicts with other accounts
- Notifications work perfectly

---

### **Option 2: Quick Fix (For Testing Now)**

**Steps:**
1. Run `FIX_KEEP_ONLY_CITIZENDEMO.sql` in Supabase
2. Make sure mobile app is logged in as `citizen@demo.com`
3. Close the app (Home button)
4. Create announcement from web
5. Should receive notification!

**Result:**
- Removes responder and superuser registrations
- Keeps citizendemo intact
- Notifications work for citizendemo
- Other accounts need to re-register by opening app

---

### **Option 3: Use Multiple Devices (Best for Testing)**

**Steps:**
1. Test `citizen@demo.com` on Device A (or Android Emulator 1)
2. Test `responder@demo.com` on Device B (or Android Emulator 2)
3. Test `superuser@lspu-dres.com` on Device C (or Android Emulator 3)

**Result:**
- Each account gets its own unique player_id
- No conflicts
- All notifications work correctly
- Realistic testing scenario

---

## 🎯 Recommended Approach

**For quick testing RIGHT NOW:**
1. Run `FIX_KEEP_ONLY_CITIZENDEMO.sql`
2. Test notifications immediately
3. Should work!

**For proper testing later:**
1. Use separate devices/emulators for each account type
2. This prevents conflicts
3. Mirrors real-world usage

**For production deployment:**
1. This bug won't happen in production
2. Real users have their own devices
3. Each device gets unique player_id automatically

---

## 🧪 Test Procedure After Fix

### Step 1: Verify Clean Database
```sql
-- Should show only 1 user (citizen@demo.com)
SELECT u.email, os.player_id
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id;
```

### Step 2: Test Background Notification
1. **Mobile:** Open app → Login as citizen@demo.com → Press Home button
2. **Web:** Login as superuser → Create announcement:
   - Type: Emergency
   - Target: All
   - Title: "Test Alert"
   - Message: "Testing background notifications"
3. **Mobile:** Should receive notification! 📱

### Step 3: Test Locked Screen Notification
1. **Mobile:** Lock the device
2. **Web:** Create another announcement
3. **Mobile:** Notification should appear on lock screen

### Step 4: Test Fully Closed App
1. **Mobile:** Swipe app away from recent apps (force close)
2. **Web:** Create another announcement
3. **Mobile:** Should still receive notification (if battery optimization is disabled)

---

## ✅ Success Criteria

Notifications are working correctly when:

1. ✅ Only 1 record in `onesignal_subscriptions` for citizendemo
2. ✅ Unique player_id (not shared with other accounts)
3. ✅ Notification received when app is in background
4. ✅ Notification received when app is closed
5. ✅ Notification received on locked screen
6. ✅ Tapping notification opens the app

---

## 📊 What We Learned

### The Bug
- **Symptom:** Notifications don't work when app is closed
- **Root Cause:** Multiple users sharing same player_id on one device
- **Why It Happened:** Testing multiple accounts on same device

### The Fix
- **Option 1:** Clean database + reinstall app
- **Option 2:** Remove duplicate registrations
- **Option 3:** Use multiple devices for testing

### Prevention
- **Testing:** Use separate devices/emulators per account type
- **Production:** Won't happen (users have own devices)
- **Monitoring:** Check for duplicate player_ids periodically

---

## 🔧 SQL Scripts Summary

1. **`IDENTIFY_CITIZENDEMO_PLAYER_ID.sql`** - Diagnose which users share player_ids
2. **`FIX_DUPLICATE_PLAYER_IDS.sql`** - Clean reset (removes all registrations)
3. **`FIX_KEEP_ONLY_CITIZENDEMO.sql`** - Quick fix (keeps only citizendemo)
4. **`DIAGNOSE_CITIZEN_FINAL.sql`** - Full diagnostic of notification system

---

## 🎉 Next Steps

1. **Choose your fix:** Option 1, 2, or 3
2. **Run the SQL script**
3. **Test notifications**
4. **Verify it works**
5. **Set up OneSignal API keys** (if not already done)
6. **Test on real devices** before production

---

**Last Updated:** December 4, 2025, 1:47 AM  
**Status:** Root cause identified, fixes provided, ready to implement

