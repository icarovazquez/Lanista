-- Publish all coach position requirements for coaches that are themselves published.
-- Without this, the matching engine's !inner join on is_published=true returns 0 coaches.

UPDATE coach_position_requirements cpr
SET is_published = TRUE
WHERE EXISTS (
  SELECT 1 FROM coaches c
  WHERE c.id = cpr.coach_id
    AND c.is_published = TRUE
);
