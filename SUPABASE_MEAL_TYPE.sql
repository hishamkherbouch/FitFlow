-- Add meal_type column to nutrition_logs for meal grouping
-- Values: breakfast, lunch, dinner, snack

ALTER TABLE nutrition_logs
ADD COLUMN IF NOT EXISTS meal_type TEXT;

-- Optional: set default meal type for existing rows
UPDATE nutrition_logs
SET meal_type = 'snack'
WHERE meal_type IS NULL;

-- Optional: add a check constraint to enforce known values
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'nutrition_logs_meal_type_check'
  ) THEN
    ALTER TABLE nutrition_logs
    ADD CONSTRAINT nutrition_logs_meal_type_check
    CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack'));
  END IF;
END $$;
