-- Revert Emergency SOS System
-- This script removes all Emergency SOS related database objects

-- Drop the view first
DROP VIEW IF EXISTS pending_emergency_sos CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS get_active_emergency_sos() CASCADE;
DROP FUNCTION IF EXISTS get_emergency_sos_stats() CASCADE;

-- Drop the table (this will cascade delete all data and indexes)
DROP TABLE IF EXISTS public.emergency_sos CASCADE;

-- Note: is_admin() function is kept as it's used by other parts of the system
-- If you need to revert is_admin() to exclude super_user, run this:
-- CREATE OR REPLACE FUNCTION public.is_admin()
-- RETURNS boolean
-- LANGUAGE sql
-- SECURITY DEFINER
-- AS $$
--   SELECT EXISTS (
--     SELECT 1 
--     FROM auth.users 
--     WHERE auth.users.id = auth.uid() 
--     AND auth.users.raw_user_meta_data->>'role' = 'admin'
--   );
-- $$;

COMMENT ON SCHEMA public IS 'Emergency SOS table and related objects have been removed';

