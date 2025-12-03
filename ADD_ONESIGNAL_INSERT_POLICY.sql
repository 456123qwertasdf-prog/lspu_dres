-- ============================================
-- Add INSERT policy for onesignal_subscriptions
-- ============================================
-- The existing policy might not allow INSERT specifically
-- Let's add explicit INSERT and UPDATE policies

-- Drop the existing broad policy if needed
-- (We'll recreate it with more specific permissions)
DROP POLICY IF EXISTS "Users can manage their own subscriptions" 
  ON onesignal_subscriptions;

-- Create separate policies for better control
CREATE POLICY "Users can insert their own subscriptions" 
  ON onesignal_subscriptions
  FOR INSERT 
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own subscriptions" 
  ON onesignal_subscriptions
  FOR SELECT 
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own subscriptions" 
  ON onesignal_subscriptions
  FOR UPDATE 
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own subscriptions" 
  ON onesignal_subscriptions
  FOR DELETE 
  TO authenticated
  USING (auth.uid() = user_id);

-- Also add policy for service role (for edge functions)
CREATE POLICY "Service role can manage all subscriptions" 
  ON onesignal_subscriptions
  FOR ALL 
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Verify policies were created
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'onesignal_subscriptions';

-- ============================================
-- AFTER RUNNING THIS:
-- ============================================
--
-- 1. MOBILE APP: Close and reopen the app
-- 2. MOBILE APP: Login as citizen@demo.com
-- 3. MOBILE APP: Wait 15 seconds
-- 4. CHECK: Look for "✅ OneSignal Player ID saved" in logs
-- 5. VERIFY: Run this query to see if it saved:
--
-- SELECT u.email, os.player_id 
-- FROM onesignal_subscriptions os
-- JOIN auth.users u ON os.user_id = u.id;
--
-- ============================================

