-- Add optional game time to player schedule
ALTER TABLE player_schedule
  ADD COLUMN event_time TIME;
