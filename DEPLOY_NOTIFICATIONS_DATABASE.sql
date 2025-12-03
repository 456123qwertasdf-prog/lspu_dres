-- ============================================
-- COMPREHENSIVE NOTIFICATION DATABASE DEPLOYMENT
-- ============================================
-- This script sets up all database requirements for notifications
-- Run this in Supabase SQL Editor

-- ============================================
-- STEP 1: Ensure onesignal_subscriptions table exists
-- ============================================
CREATE TABLE IF NOT EXISTS onesignal_subscriptions (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  player_id text NOT NULL,
  platform text DEFAULT 'android',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, player_id)
);

-- Enable RLS
ALTER TABLE onesignal_subscriptions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 2: Drop existing policies (if any)
-- ============================================
DROP POLICY IF EXISTS "Users can manage their own subscriptions" ON onesignal_subscriptions;
DROP POLICY IF EXISTS "Users can insert their own subscriptions" ON onesignal_subscriptions;
DROP POLICY IF EXISTS "Users can view their own subscriptions" ON onesignal_subscriptions;
DROP POLICY IF EXISTS "Users can update their own subscriptions" ON onesignal_subscriptions;
DROP POLICY IF EXISTS "Users can delete their own subscriptions" ON onesignal_subscriptions;
DROP POLICY IF EXISTS "Service role can manage all subscriptions" ON onesignal_subscriptions;

-- ============================================
-- STEP 3: Create proper RLS policies
-- ============================================

-- Policy for INSERT
CREATE POLICY "Users can insert their own subscriptions" 
  ON onesignal_subscriptions
  FOR INSERT 
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Policy for SELECT
CREATE POLICY "Users can view their own subscriptions" 
  ON onesignal_subscriptions
  FOR SELECT 
  TO authenticated
  USING (auth.uid() = user_id);

-- Policy for UPDATE
CREATE POLICY "Users can update their own subscriptions" 
  ON onesignal_subscriptions
  FOR UPDATE 
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy for DELETE
CREATE POLICY "Users can delete their own subscriptions" 
  ON onesignal_subscriptions
  FOR DELETE 
  TO authenticated
  USING (auth.uid() = user_id);

-- Policy for service role (for edge functions)
CREATE POLICY "Service role can manage all subscriptions" 
  ON onesignal_subscriptions
  FOR ALL 
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ============================================
-- STEP 4: Create get_super_users function
-- ============================================

-- Drop existing function first (if it exists with different signature)
DROP FUNCTION IF EXISTS public.get_super_users();

-- Create the function with correct return type
CREATE OR REPLACE FUNCTION public.get_super_users()
RETURNS TABLE (
  id uuid,
  email text,
  role text,
  onesignal_player_id text
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT 
    os.user_id as id,
    u.email::text,
    (u.raw_user_meta_data->>'role')::text as role,
    os.player_id as onesignal_player_id
  FROM onesignal_subscriptions os
  JOIN auth.users u ON os.user_id = u.id
  WHERE u.raw_user_meta_data->>'role' IN ('super_user', 'admin')
  ORDER BY os.updated_at DESC;
$$;

-- ============================================
-- STEP 5: Verify setup
-- ============================================

-- Check table exists
SELECT 
  '✅ Table Check' as status,
  CASE 
    WHEN EXISTS (
      SELECT FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'onesignal_subscriptions'
    ) THEN '✅ onesignal_subscriptions table exists'
    ELSE '❌ Table missing'
  END as result;

-- Check policies
SELECT 
  '✅ Policy Check' as status,
  COUNT(*) || ' policies created' as result
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'onesignal_subscriptions';

-- Check function
SELECT 
  '✅ Function Check' as status,
  CASE 
    WHEN EXISTS (
      SELECT FROM information_schema.routines 
      WHERE routine_schema = 'public' 
      AND routine_name = 'get_super_users'
    ) THEN '✅ get_super_users() function exists'
    ELSE '❌ Function missing'
  END as result;

-- Show current subscriptions
SELECT 
  '📊 Current Subscriptions' as status,
  COUNT(*) || ' users registered' as result
FROM onesignal_subscriptions;

-- ============================================
-- DEPLOYMENT COMPLETE! 🎉
-- ============================================
-- 
-- NEXT STEPS:
-- 1. ✅ Edge functions deployed (DONE via CLI)
-- 2. ✅ Database setup complete (DONE - you just ran this)
-- 3. ⏳ Users need to open mobile app to register
-- 4. ⏳ Test notifications
--
-- TO TEST:
-- 1. Open mobile app and login
-- 2. Create an announcement or assign a responder
-- 3. Check if notification is received
--
-- TO VERIFY REGISTRATION:
-- Run this query:
-- SELECT u.email, os.player_id, os.updated_at
-- FROM onesignal_subscriptions os
-- JOIN auth.users u ON os.user_id = u.id
-- ORDER BY os.updated_at DESC;
-- ============================================

