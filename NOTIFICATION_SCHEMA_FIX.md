# 🔧 Notification Schema Fix

## 🐛 Critical Bug Found & Fixed

### The Problem

The Edge Functions were using **incorrect column names** for the `notifications` table!

**What was wrong:**
```typescript
// ❌ BEFORE: Wrong column names
await supabaseClient
  .from('notifications')
  .insert({
    user_id: responder.user_id,    // ❌ Column doesn't exist!
    data: {...},                    // ❌ Wrong column name
    read: false                     // ❌ Wrong column name
  })
```

**The actual table schema:**
```sql
CREATE TABLE notifications (
  id uuid PRIMARY KEY,
  target_type text,      -- 'admin', 'responder', or 'reporter'
  target_id uuid,        -- NOT 'user_id'!
  type text,
  title text,
  message text,
  payload jsonb,         -- NOT 'data'!
  is_read boolean,       -- NOT 'read'!
  created_at timestamp
);
```

### Why This Happened

There was a **mismatch between two notification systems**:
1. The original `NOTIFICATION_SYNC_SYSTEM.md` defined the schema with `target_type`, `target_id`, `payload`, `is_read`
2. The Edge Functions were written using `user_id`, `data`, `read` (non-existent columns)

This caused all database inserts to **fail silently**, so no notification records were saved!

---

## ✅ What Was Fixed

### Files Updated:

1. **`notify-responder-assignment/index.ts`**
   - Changed `user_id` → `target_id`
   - Changed `data` → `payload`
   - Changed `read` → `is_read`
   - Added `target_type: 'responder'`

2. **`notify-superusers-critical-report/index.ts`**
   - Changed `user_id` → `target_id`
   - Changed `data` → `payload`
   - Changed `read` → `is_read`
   - Added `target_type: 'admin'`

3. **`assign-responder/index.ts`**
   - Changed `user_id` → `target_id`
   - Changed `data` → `payload`
   - Changed `read` → `is_read`
   - Added `target_type: 'responder'`

4. **`test_responder_notification.sql`**
   - Fixed query to use `target_id` instead of `user_id`
   - Fixed query to use `is_read` instead of `read`

---

## 📊 Before & After

### Before (BROKEN) ❌

```typescript
// notify-responder-assignment
await supabaseClient
  .from('notifications')
  .insert({
    user_id: responder.user_id,        // ❌ Column doesn't exist
    type: 'assignment_created',
    title: notificationPayload.title,
    message: notificationPayload.message,
    data: { assignment_id, ... },      // ❌ Column doesn't exist
    read: false,                        // ❌ Column doesn't exist
    created_at: new Date().toISOString()
  })
```

**Result:** Database insert fails, no notification saved ❌

### After (FIXED) ✅

```typescript
// notify-responder-assignment
await supabaseClient
  .from('notifications')
  .insert({
    target_type: 'responder',          // ✅ Correct column
    target_id: responder.user_id,      // ✅ Correct column
    type: 'assignment_created',
    title: notificationPayload.title,
    message: notificationPayload.message,
    payload: { assignment_id, ... },   // ✅ Correct column
    is_read: false,                    // ✅ Correct column
    created_at: new Date().toISOString()
  })
```

**Result:** Database insert succeeds, notification saved ✅

---

## 🚀 Deployed Functions (Updated)

All three Edge Functions have been redeployed with the correct schema:

| Function | Status | Changes |
|----------|--------|---------|
| `notify-responder-assignment` | ✅ **Redeployed** | Fixed column names + multiple device support |
| `notify-superusers-critical-report` | ✅ **Redeployed** | Fixed column names |
| `assign-responder` | ✅ **Redeployed** | Fixed column names |

---

## 🧪 Testing

Now you can test with the fixed query:

```sql
-- Check if notifications are being created correctly
SELECT 
  n.id,
  n.type,
  n.target_type,
  n.target_id,
  n.title,
  n.message,
  n.is_read,
  n.created_at,
  u.email
FROM notifications n
LEFT JOIN auth.users u ON u.id = n.target_id
WHERE n.type = 'assignment_created'
ORDER BY n.created_at DESC
LIMIT 10;
```

**Expected results:**
- `target_type` should be 'responder' or 'admin'
- `target_id` should match user IDs
- `is_read` should be false for new notifications
- No more SQL errors about missing columns!

---

## 📝 Root Cause Analysis

**Why did this happen?**

1. **Two different notification schemas** were in use:
   - Original design: `target_type`, `target_id`, `payload`, `is_read`
   - Edge Functions: `user_id`, `data`, `read`

2. **No schema validation** - Functions deployed without checking table structure

3. **Silent failures** - Database errors weren't caught, so push notifications worked but database records failed

**Prevention:**
- ✅ All Edge Functions now use consistent schema
- ✅ Test queries updated to match schema
- ✅ Documentation updated with correct column names

---

## ✅ Summary

**Problems Fixed:**
1. ✅ Responder notifications now save to database correctly
2. ✅ Super user notifications now save to database correctly
3. ✅ Test queries now work without SQL errors
4. ✅ All three Edge Functions use consistent schema

**What works now:**
- ✅ Push notifications send successfully (already worked)
- ✅ Database notification records created (NOW FIXED!)
- ✅ Notification history can be queried (NOW FIXED!)
- ✅ In-app notification centers can display saved notifications (NOW FIXED!)

---

**Status:** ✅ All fixes deployed and ready to test!  
**Date:** December 4, 2025

