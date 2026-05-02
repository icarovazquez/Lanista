-- Add program website URL to coaches
ALTER TABLE coaches
  ADD COLUMN IF NOT EXISTS website_url TEXT;
