-- Seed coach_position_requirements for coaches that have roster_slots
-- but no position requirements. Without these, the matching engine's !inner
-- join skips these coaches entirely, leaving players with "Score pending".
--
-- Uses the distinct position_keys from each coach's roster_slots as the
-- requirement list. Physical/academic thresholds are left NULL (no restrictions)
-- so all players are considered; the matching engine will still score partial matches.

INSERT INTO coach_position_requirements (coach_id, position_key, is_published)
SELECT DISTINCT
  rs.coach_id,
  rs.position_key,
  TRUE
FROM roster_slots rs
WHERE rs.position_key IS NOT NULL
  AND NOT EXISTS (
    SELECT 1
    FROM coach_position_requirements cpr
    WHERE cpr.coach_id = rs.coach_id
      AND cpr.position_key = rs.position_key
  )
  AND EXISTS (
    SELECT 1 FROM coaches c
    WHERE c.id = rs.coach_id
      AND c.is_published = TRUE
  );
