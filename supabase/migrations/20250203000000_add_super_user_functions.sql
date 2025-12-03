-- Create function to get all super users and admins
-- This function returns users with super_user or admin roles including their OneSignal player IDs
-- Note: Users may have multiple player IDs (one per device), so we return all of them

CREATE OR REPLACE FUNCTION public.get_super_users()
RETURNS TABLE (
  id uuid,
  email text,
  onesignal_player_id text,
  raw_user_meta_data jsonb
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT DISTINCT
    u.id,
    u.email,
    os.player_id as onesignal_player_id,
    u.raw_user_meta_data
  FROM auth.users u
  LEFT JOIN public.onesignal_subscriptions os ON os.user_id = u.id
  WHERE u.raw_user_meta_data->>'role' IN ('super_user', 'admin')
  AND u.deleted_at IS NULL;
$$;

-- Create function to get users by specific roles
-- This function accepts an array of role names and returns matching users
-- Note: Users may have multiple player IDs (one per device), so we return all of them

CREATE OR REPLACE FUNCTION public.get_users_by_role(role_names text[])
RETURNS TABLE (
  id uuid,
  email text,
  onesignal_player_id text,
  role text
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT DISTINCT
    u.id,
    u.email,
    os.player_id as onesignal_player_id,
    u.raw_user_meta_data->>'role' as role
  FROM auth.users u
  LEFT JOIN public.onesignal_subscriptions os ON os.user_id = u.id
  WHERE u.raw_user_meta_data->>'role' = ANY(role_names)
  AND u.deleted_at IS NULL;
$$;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION public.get_super_users() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_super_users() TO service_role;
GRANT EXECUTE ON FUNCTION public.get_super_users() TO anon;

GRANT EXECUTE ON FUNCTION public.get_users_by_role(text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_users_by_role(text[]) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_users_by_role(text[]) TO anon;

-- Add helpful comments
COMMENT ON FUNCTION public.get_super_users() IS 'Returns all users with super_user or admin roles including their OneSignal player IDs for push notifications';
COMMENT ON FUNCTION public.get_users_by_role(text[]) IS 'Returns users filtered by the specified role names from raw_user_meta_data';

