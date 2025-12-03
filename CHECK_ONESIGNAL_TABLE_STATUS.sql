-- ============================================
-- Check if onesignal_subscriptions table exists
-- and has correct permissions
-- ============================================

-- 1. Check if table exists
SELECT 
  '1️⃣ Table Status' as check_name,
  CASE 
    WHEN EXISTS (
      SELECT FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'onesignal_subscriptions'
    ) THEN '✅ Table EXISTS'
    ELSE '❌ Table MISSING - Need to run migration!'
  END as status;

-- 2. Check table structure
SELECT 
  '2️⃣ Table Columns' as check_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'onesignal_subscriptions'
ORDER BY ordinal_position;

-- 3. Check RLS policies
SELECT 
  '3️⃣ RLS Policies' as check_name,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'onesignal_subscriptions';

-- 4. Check unique constraints
SELECT 
  '4️⃣ Unique Constraints' as check_name,
  constraint_name,
  constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'public' 
  AND table_name = 'onesignal_subscriptions';

-- ============================================
-- WHAT TO LOOK FOR:
-- ============================================
--
-- 1️⃣ Table Status: Should say "✅ Table EXISTS"
--    If "❌ Table MISSING" → Need to run migration:
--    supabase/migrations/20250130000001_add_onesignal_subscriptions.sql
--
-- 2️⃣ Table Columns: Should show:
--    - id (uuid)
--    - user_id (uuid)
--    - player_id (text)
--    - platform (text)
--    - created_at (timestamptz)
--    - updated_at (timestamptz)
--
-- 3️⃣ RLS Policies: Should show at least one policy
--    "Users can manage their own subscriptions"
--
-- 4️⃣ Unique Constraints: Should show unique constraint on (user_id, player_id)
--
-- ============================================

