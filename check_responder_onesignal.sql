-- Check which responders have OneSignal player IDs registered
SELECT 
  r.id as responder_id,
  r.name as responder_name,
  r.user_id,
  u.email,
  u.raw_user_meta_data->>'role' as role,
  os.player_id as onesignal_player_id,
  os.created_at as registered_at,
  os.updated_at
FROM responder r
JOIN auth.users u ON u.id = r.user_id
LEFT JOIN onesignal_subscriptions os ON os.user_id = r.user_id
WHERE u.deleted_at IS NULL
ORDER BY r.name;

-- This will show which responders can receive push notifications

