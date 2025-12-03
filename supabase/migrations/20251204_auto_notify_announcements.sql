-- Migration: Auto-notify users when new announcements are created
-- This ensures mobile app alerts work the same as web admin alerts

-- OPTION 1: Database Trigger (if pg_net extension is available)
-- Uncomment this section if you want automatic notifications via database trigger

/*
-- Enable pg_net extension (requires Supabase project)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Create function to trigger announcement notifications
CREATE OR REPLACE FUNCTION public.trigger_announcement_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  request_id bigint;
BEGIN
  -- Only notify if announcement is active
  IF NEW.status = 'active' THEN
    -- Use pg_net to call the edge function asynchronously
    SELECT net.http_post(
      url := current_setting('app.settings')::json->>'supabase_url' || '/functions/v1/announcement-notify',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings')::json->>'service_role_key'
      ),
      body := jsonb_build_object(
        'announcementId', NEW.id::text
      )
    ) INTO request_id;
    
    RAISE NOTICE 'Triggered announcement notification for % (request: %)', NEW.id, request_id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger
DROP TRIGGER IF EXISTS on_announcement_created ON public.announcements;
CREATE TRIGGER on_announcement_created
  AFTER INSERT ON public.announcements
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_announcement_notification();
*/

-- OPTION 2: Application-Level Notifications (RECOMMENDED)
-- The mobile app now calls announcement-notify function directly after creating announcements
-- This is more reliable than database triggers for HTTP calls

-- Add comment to document the notification flow
COMMENT ON TABLE public.announcements IS 
'Admin-created announcements and alerts. ' ||
'After inserting, call announcement-notify edge function to send push notifications.';

-- For web admin: Use Database Webhook (configure in Supabase Dashboard)
-- 1. Go to Database > Webhooks
-- 2. Create webhook for 'announcements' table
-- 3. Event: INSERT
-- 4. URL: https://your-project.supabase.co/functions/v1/announcement-notify
-- 5. HTTP Method: POST
-- 6. Body: {"announcementId": "{{ record.id }}"}

-- For mobile app: The code now calls announcement-notify directly after insert

