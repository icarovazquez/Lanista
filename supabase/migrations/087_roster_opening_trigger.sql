-- 087: Postgres trigger → notify-roster-opening Edge Function
-- Fires when a roster slot transitions to needs_recruit = TRUE
-- (slot_status: graduating, portal_risk, or open)
--
-- Requires pg_net extension (enabled by default on Supabase hosted).
-- The Edge Function reads SUPABASE_SERVICE_ROLE_KEY + FCM_SERVER_KEY from its env.

CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE OR REPLACE FUNCTION trigger_notify_roster_opening()
RETURNS trigger AS $$
BEGIN
  -- Fire only when needs_recruit transitions to TRUE (new opening)
  IF NEW.needs_recruit = TRUE AND (
    TG_OP = 'INSERT' OR OLD.needs_recruit IS DISTINCT FROM TRUE
  ) THEN
    PERFORM net.http_post(
      url     := 'https://yfyutdbxfwqajzsejenz.supabase.co/functions/v1/notify-roster-opening',
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmeXV0ZGJ4ZndxYWp6c2VqZW56Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzOTE4NTgsImV4cCI6MjA4Njk2Nzg1OH0.o_6HsgASe0toPcuaoijhhlP6WgsZN2T9LmONDKMEATg'
      ),
      body    := jsonb_build_object(
        'coach_id',        NEW.coach_id,
        'position_key',    NEW.position_key,
        'graduation_year', NEW.graduation_year,
        'slot_status',     NEW.slot_status
      )::text
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_roster_slot_opening
  AFTER INSERT OR UPDATE OF slot_status ON roster_slots
  FOR EACH ROW
  EXECUTE FUNCTION trigger_notify_roster_opening();
