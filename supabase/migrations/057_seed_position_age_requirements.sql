-- 057 · Seed age requirements for existing coach position requirements
-- Sets min_age_years = 20 and max_age_years = 25 for ~80 % of positions.
-- The remaining ~20 % are left without age constraints (NULL) to keep data realistic.

UPDATE coach_position_requirements
SET
  min_age_years = 20,
  max_age_years = 25
WHERE
  -- Target roughly 80 % of rows using a stable hash of the row id
  abs(hashtext(id::text)) % 10 < 8;
