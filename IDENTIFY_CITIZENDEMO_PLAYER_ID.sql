-- ============================================
-- Find out which user is citizendemo
-- ============================================

SELECT 
  u.email,
  u.raw_user_meta_data->>'role' as role,
  os.user_id,
  os.player_id,
  os.created_at,
  os.updated_at,
  CASE 
    WHEN u.email LIKE '%citizen%' OR u.email LIKE '%demo%' THEN '🎯 THIS IS CITIZENDEMO'
    ELSE ''
  END as is_citizendemo
FROM onesignal_subscriptions os
JOIN auth.users u ON os.user_id = u.id
ORDER BY os.created_at DESC;

-- ============================================
-- This will show you:
-- - Which email corresponds to each player_id
-- - Which one is citizendemo
-- - If they all have the same player_id (BUG!)
-- ============================================

