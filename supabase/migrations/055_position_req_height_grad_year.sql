-- 055 · Add height and graduation year requirements to coach_position_requirements
-- Coaches can now specify min height (cm) and a graduation year range per position.

ALTER TABLE coach_position_requirements
  ADD COLUMN IF NOT EXISTS min_height_cm  INTEGER,   -- e.g. 180 (minimum height in cm)
  ADD COLUMN IF NOT EXISTS min_grad_year  INTEGER,   -- e.g. 2026
  ADD COLUMN IF NOT EXISTS max_grad_year  INTEGER;   -- e.g. 2028
