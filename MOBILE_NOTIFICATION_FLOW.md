# 📱 Mobile App Notification Flow

## 🔄 Complete Assignment Flow (FIXED)

```
┌─────────────────────────────────────────────────────────────────────┐
│                         MOBILE SUPER USER                           │
│                                                                     │
│  📱 Opens Mobile App → Reports → Select Report → Edit              │
│                                                                     │
│  👆 Selects Responder → Taps "Save Changes"                        │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    MOBILE APP (Flutter)                             │
│                                                                     │
│  ✅ NEW CODE:                                                       │
│  await SupabaseService.client.functions.invoke(                    │
│    'assign-responder',                                             │
│    body: {                                                         │
│      'report_id': reportId,                                        │
│      'responder_id': responderId,                                  │
│    },                                                              │
│  );                                                                │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│              EDGE FUNCTION: assign-responder                        │
│                                                                     │
│  1. ✅ Validate report exists                                       │
│  2. ✅ Validate responder exists and available                      │
│  3. ✅ Cancel existing assignments (if any)                         │
│  4. ✅ Create new assignment in database                            │
│  5. ✅ Update report with responder_id                              │
│  6. ✅ Create in-app notification                                   │
│  7. ✅ Emit real-time events                                        │
│  8. ✅ Call notify-responder-assignment function                    │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│         EDGE FUNCTION: notify-responder-assignment                  │
│                                                                     │
│  1. ✅ Get responder details from database                          │
│  2. ✅ Get report details (type, priority, severity)                │
│  3. ✅ Query onesignal_subscriptions for player IDs                 │
│  4. ✅ Determine notification priority:                             │
│     - 🔴 CRITICAL/HIGH (priority ≤ 2)                               │
│     - 🟠 NORMAL (priority 3-4)                                      │
│  5. ✅ Build notification payload with deep link                    │
│  6. ✅ Send to OneSignal API                                        │
│  7. ✅ Log notification in database                                 │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      ONESIGNAL API                                  │
│                                                                     │
│  📡 Receives notification request                                   │
│  📤 Sends push notification to device(s)                            │
│  🔔 Handles delivery and tracking                                   │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    RESPONDER'S MOBILE DEVICE                        │
│                                                                     │
│  📱 Receives push notification                                      │
│  🔔 Shows notification banner                                       │
│  🔊 Plays notification sound                                        │
│  👆 Tap to open app → Deep link to assignment                       │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│              RESPONDER MOBILE APP (Flutter)                         │
│                                                                     │
│  ✅ App opens to assignment details                                 │
│  ✅ Shows report information                                        │
│  ✅ Responder can Accept/Decline                                    │
│  ✅ Real-time updates via Supabase Realtime                         │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔴 Critical Priority Flow

```
Fire Report (Priority 1)
         ↓
Super User Assigns via Mobile
         ↓
assign-responder Edge Function
         ↓
notify-responder-assignment
         ↓
🔴 CRITICAL NOTIFICATION
   - Red badge
   - Emergency sound
   - High priority delivery
         ↓
Responder's Device
```

---

## 🟠 Normal Priority Flow

```
Flood Report (Priority 3)
         ↓
Super User Assigns via Mobile
         ↓
assign-responder Edge Function
         ↓
notify-responder-assignment
         ↓
🟠 NORMAL NOTIFICATION
   - Orange badge
   - Default sound
   - Standard delivery
         ↓
Responder's Device
```

---

## 📊 Database Updates

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DATABASE CHANGES                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. assignment table:                                               │
│     INSERT INTO assignment (                                        │
│       report_id,                                                    │
│       responder_id,                                                 │
│       status = 'assigned',                                          │
│       assigned_at = NOW()                                           │
│     )                                                               │
│                                                                     │
│  2. reports table:                                                  │
│     UPDATE reports SET                                              │
│       responder_id = [responder_id],                                │
│       assignment_id = [assignment_id],                              │
│       lifecycle_status = 'assigned'                                 │
│                                                                     │
│  3. notifications table:                                            │
│     INSERT INTO notifications (                                     │
│       target_type = 'responder',                                    │
│       target_id = [user_id],                                        │
│       type = 'assignment_created',                                  │
│       title = '🚨 New Emergency Assignment',                        │
│       message = 'You've been assigned to a [TYPE] report',         │
│       payload = { assignment_id, report_id, ... }                  │
│     )                                                               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Real-time Events

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SUPABASE REALTIME CHANNELS                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Channel: responder_assignments                                     │
│  Event: assignment_created                                          │
│  Payload: {                                                         │
│    assignment_id,                                                   │
│    report_id,                                                       │
│    responder_id,                                                    │
│    report_type,                                                     │
│    priority                                                         │
│  }                                                                  │
│                                                                     │
│  ↓ Subscribers:                                                     │
│  - Responder Dashboard (Web)                                        │
│  - Responder Mobile App                                             │
│  - Super User Dashboard (Web)                                       │
│  - Super User Mobile App                                            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🎯 Notification Payload

```json
{
  "app_id": "ONESIGNAL_APP_ID",
  "include_player_ids": ["player_id_1", "player_id_2"],
  "headings": {
    "en": "🚨 New Emergency Assignment"
  },
  "contents": {
    "en": "You've been assigned to a FIRE report\nLocation: Sta. Cruz Campus\nPriority: CRITICAL"
  },
  "data": {
    "type": "assignment",
    "assignment_id": "uuid-here",
    "report_id": "uuid-here",
    "report_type": "fire",
    "priority": 1,
    "severity": "CRITICAL"
  },
  "url": "lspu-dres://assignment/uuid-here",
  "priority": 10,
  "android_channel_id": "emergency_alerts",
  "ios_sound": "emergency.wav",
  "android_sound": "emergency"
}
```

---

## 🔍 Comparison: Before vs After

### ❌ BEFORE (BROKEN)

```
Mobile App
    ↓
Direct Database Insert
    ↓
assignment table updated
    ↓
❌ NO NOTIFICATIONS
❌ NO PUSH ALERTS
❌ NO REAL-TIME EVENTS
```

### ✅ AFTER (FIXED)

```
Mobile App
    ↓
assign-responder Edge Function
    ↓
Database Updates
    ↓
notify-responder-assignment Edge Function
    ↓
OneSignal API
    ↓
✅ PUSH NOTIFICATION SENT
✅ IN-APP NOTIFICATION CREATED
✅ REAL-TIME EVENTS EMITTED
✅ RESPONDER NOTIFIED IMMEDIATELY
```

---

## 📱 User Experience

### Super User (Mobile App):
1. 👆 Tap report → Edit
2. 🔽 Select responder
3. 💾 Tap Save
4. ✅ See "Report updated successfully!"
5. 📊 Dashboard updates in real-time

### Responder (Mobile Device):
1. 📱 Receive push notification (within seconds)
2. 🔔 Hear notification sound
3. 👀 See notification banner
4. 👆 Tap notification
5. 📲 App opens to assignment details
6. ✅ Can Accept/Decline immediately

---

## 🎉 Result

**Mobile super users can now notify responders when assigning reports!**

The notification system works identically whether the assignment is made from:
- ✅ Web Dashboard
- ✅ Mobile App

Both interfaces now provide the same notification experience for responders.

---

**Status:** ✅ COMPLETE  
**Date:** December 4, 2025

