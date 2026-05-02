-- Migration 068: Allow players to read roster slots for published coaches
-- Fixes: "Recruiting Now" filter in player search returning no results
-- Root cause: roster_slots RLS only had an owner policy for coaches;
--   players querying coaches with roster_slots(needs_recruit) got empty arrays.

CREATE POLICY "roster_slots_published_read" ON roster_slots
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM coaches
      WHERE id = roster_slots.coach_id
        AND is_published = true
    )
  );
