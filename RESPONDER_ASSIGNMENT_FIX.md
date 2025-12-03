# Responder Assignment & Notifications Fix

## Problem Summary

### Issue 1: Responder Notifications Not Working ❌
When assigning a responder through the web interface (Super User Reports page):
- The "Report Details" modal allows editing and assigning a responder
- Clicking "Save Changes" updated the database directly
- **No push notifications were sent to responders**
- The `assign-responder` Edge Function was deployed but never called

### Issue 2: Image Duplicate Checking Clarification ✅
- The `check-image-duplicate` Edge Function exists and is working
- However, it's not called because duplicate checking happens **inline** during report submission
- The `submit-report` function automatically checks for and handles duplicate images
- This is working correctly - no fix needed

---

## What Was Fixed

### 1. Web Interface Assignment Flow ✅

**File Changed:** `public/super-user-reports.html`

**Before:** Direct database manipulation
```javascript
// Old code directly inserted/updated assignments in database
const { data: newAssignment } = await supabase
    .from('assignment')
    .insert({ ... });
```

**After:** Calls Edge Function
```javascript
// New code calls the assign-responder Edge Function
const { data: assignResult } = await supabase.functions.invoke('assign-responder', {
    body: {
        report_id: currentReportId,
        responder_id: selectedResponderId,
        assigned_by: userId
    }
});
```

**Benefits:**
- ✅ Push notifications are now sent to responders via OneSignal
- ✅ Critical/high priority reports trigger emergency alerts
- ✅ Audit logging happens automatically
- ✅ Real-time updates are broadcast to all connected clients
- ✅ Proper error handling and validation

### 2. Edge Functions Deployed ✅

**Deployed Functions:**
1. `assign-responder` - Handles responder assignments (updated)
2. `notify-responder-assignment` - Sends push notifications (newly deployed)

**Deployment Commands:**
```bash
supabase functions deploy assign-responder
supabase functions deploy notify-responder-assignment
```

---

## How It Works Now

### Assignment Flow

```
Super User clicks "Save Changes" in Report Details modal
    ↓
Web app calls assign-responder Edge Function
    ↓
Edge Function validates report & responder
    ↓
Creates assignment in database
    ↓
Updates report status to "assigned"
    ↓
Calls notify-responder-assignment function
    ↓
Sends push notification via OneSignal
    ↓
Responder receives notification on mobile device
    ↓
Real-time events broadcast to all connected clients
```

### Push Notification Features

**For Critical/High Priority Reports:**
- 🚨 Red notification color
- 📢 Emergency alert sound
- 🔔 Persistent notification (grouped)
- ⚡ Priority level 10

**For Normal Priority Reports:**
- 🔔 Orange notification color
- 🎵 Default notification sound
- ⚡ Priority level 7

**Notification Content:**
- Report type and emergency icon
- Response time requirement
- Location address
- Assignment details for opening in app

---

## Web Report Submission Fix ✅ FIXED

### Problem
The web form (`user.html`) was **NOT using the `submit-report` Edge Function**! It was:
- ❌ Uploading images directly to storage (no deduplication)
- ❌ Inserting reports directly into database
- ❌ Triggering AI separately

### Solution
Updated `public/user.html` to use the `submit-report` Edge Function like the mobile app does:
- ✅ Now calls the Edge Function with FormData
- ✅ Image deduplication now works for web submissions
- ✅ Logs appear in Supabase dashboard
- ✅ Same code path as mobile app

## Image Duplicate Checking & Smart Classification Reuse ✅ FIXED

### Problem Before
- Images were being deduplicated (reused) ✅
- BUT AI classification was **running every time** ❌
- This wasted Azure API calls and processing time

### Solution Now

**Location:** `supabase/functions/submit-report/index.ts`

The `submit-report` function now **intelligently reuses classifications**:

```javascript
// 1. Compute image hash
const imageHash = await computeImageHash(arrayBuffer)

// 2. Check if image already exists
const { data: dedupRecord } = await supabase
    .from('image_deduplication')
    .select('image_path')
    .eq('image_hash', imageHash)
    .maybeSingle()

// 3. If duplicate found, reuse existing image
if (dedupRecord && dedupRecord.image_path) {
    console.log('Deduplication hit, reusing existing image')
    return { imagePath: dedupRecord.image_path, isDuplicate: true }
}

// 4. If new image, upload to storage
const { data: uploadData } = await supabase.storage
    .from('reports-images')
    .upload(fileName, imageFile)

// 5. SMART CLASSIFICATION ✨ NEW!
if (isDuplicate) {
    // Find existing report with same image hash that was already classified
    const existingClassification = await findExistingClassification(imageHash)
    
    if (existingClassification) {
        // Copy classification (type, confidence, priority, severity, etc.)
        console.log('✅ Reusing classification from previous report')
        await copyClassificationToNewReport(newReportId, existingClassification)
        
        // Still notify super users if critical
        if (isCritical) {
            await notifySuperUsers(newReportId)
        }
    } else {
        // Duplicate image but not classified yet - run AI
        await triggerAIClassification(newReportId)
    }
} else {
    // Brand new image - always run AI classification
    await triggerAIClassification(newReportId)
}
```

### Standalone Function (Optional)

**Function:** `check-image-duplicate`

This function can be used for **pre-upload checking** (e.g., to warn users before they submit):

```javascript
// Call from mobile app or web app before uploading
const { data } = await supabase.functions.invoke('check-image-duplicate', {
    body: {
        imageBuffer: base64Image,  // or
        imageHash: precomputedHash
    }
});

if (data.isDuplicate) {
    // Show warning: "This image was already reported"
    // data.existingPath contains the path to existing image
}
```

**Use Cases:**
- Show warning before report submission
- Prevent accidental duplicate reports
- Save bandwidth by not uploading duplicates

---

## Testing the Fix

### Test Responder Notifications

1. **Open Super User Reports Page:**
   ```
   https://your-site.workers.dev/super-user-reports
   ```

2. **Click on any report** to open the "Report Details" modal

3. **Click "Edit"** button (toggle icon in modal)

4. **Select a responder** from the "Assign Responder" dropdown

5. **Click "Save Changes"**

6. **Expected Results:**
   - ✅ Report status changes to "ASSIGNED"
   - ✅ Responder's mobile device receives push notification
   - ✅ Success message appears in web interface
   - ✅ Logs appear in Supabase Edge Functions dashboard

### Check Logs

**assign-responder logs:**
```
https://supabase.com/dashboard/project/your-project/functions/assign-responder/logs
```

You should see:
- Assignment creation
- Report update
- Push notification sent

**notify-responder-assignment logs:**
```
https://supabase.com/dashboard/project/your-project/functions/notify-responder-assignment/logs
```

You should see:
- OneSignal API call
- Notification payload
- Send confirmation

---

## Troubleshooting

### No Logs Appearing

**Possible Causes:**
1. Functions not called (check web console for errors)
2. OneSignal not configured (check env vars)
3. Responder has no OneSignal player ID

**Check:**
```javascript
// Browser console should show:
console.log('✅ Responder assigned successfully with notification:', assignResult)
```

### Notifications Not Received

**Check:**
1. Responder's OneSignal player ID in `users` table
2. OneSignal credentials in Supabase Edge Function secrets
3. Mobile app has notification permissions
4. OneSignal is initialized in mobile app

### Assignment Fails

**Common Errors:**
- `Report not found` - Invalid report ID
- `Responder not found` - Invalid responder ID
- `Report already assigned` - Clear existing assignment first
- `Responder not available` - Responder status not active

---

## Summary of All Fixes

### Fix #1: Responder Notifications ✅
**Problem:** Web interface edited reports directly in database, bypassing the `assign-responder` function
**Solution:** Updated `public/super-user-reports.html` to call the Edge Function
**Result:** Responders now receive push notifications when assigned

### Fix #2: Web Report Submission ✅  
**Problem:** Web form uploaded images directly, bypassing the `submit-report` function
**Solution:** Updated `public/user.html` to use the `submit-report` Edge Function
**Result:** Image deduplication now works for web submissions, logs appear in dashboard

### Fix #3: Smart Classification Reuse ✅ NEW!
**Problem:** Duplicate images were reused BUT AI classification ran every time (wasteful)
**Solution:** Added `copyExistingClassification()` function to reuse previous classifications
**Result:** Same image = same classification automatically copied, saves Azure API calls

### Fix #4: Edge Functions Deployed ✅
**Deployed:**
- `assign-responder` (updated with notification code)
- `notify-responder-assignment` (newly deployed)
- `submit-report` (updated with smart classification reuse)

---

## What Now Works

✅ **Responder notifications** - Push alerts sent when assigning responders via web
✅ **Image deduplication** - Both mobile app and web check for duplicate images
✅ **Smart classification reuse** - Same image = reuse previous AI classification automatically
✅ **Unified code path** - Web and mobile use same Edge Functions
✅ **Complete logging** - All activity appears in Supabase dashboard
📱 **Emergency alerts** - Critical reports trigger special notifications
💰 **Cost savings** - No more duplicate Azure Vision API calls for same images

**No further action needed** - the system is now fully functional!

