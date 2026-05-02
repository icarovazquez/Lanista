-- ── 079: Add 'signed' stage to pipeline_stage enum ───────────────────────────
-- Required for ROI tracking (migration 080). Must be a separate committed
-- transaction before the enum value can be used in DML.
ALTER TYPE pipeline_stage ADD VALUE IF NOT EXISTS 'signed';
