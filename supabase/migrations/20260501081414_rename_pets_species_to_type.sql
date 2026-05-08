-- Drop the unused `species` column if it exists (replaced by `type`)
ALTER TABLE pets DROP COLUMN IF EXISTS species;
