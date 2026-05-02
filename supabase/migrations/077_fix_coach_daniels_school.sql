-- ── 077: Fix Coach Daniels school_name ──────────────────────────────────────
-- school_name was incorrectly set to 'UT Austin'; bio/state/website all point
-- to University of North Carolina (UNC).
UPDATE coaches
SET school_name = 'University of North Carolina'
WHERE id = 'c3000000-0000-0000-0000-000000000001';
