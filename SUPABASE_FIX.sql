-- Fix for missing columns in nutrition_logs table

-- 1. Add 'grams' column if it doesn't exist
ALTER TABLE nutrition_logs 
ADD COLUMN IF NOT EXISTS grams DOUBLE PRECISION DEFAULT 0;

-- 2. Add 'logged_at' column if it doesn't exist
ALTER TABLE nutrition_logs 
ADD COLUMN IF NOT EXISTS logged_at TIMESTAMPTZ DEFAULT NOW();

-- 3. If you have an old 'amount_grams' column, you might want to rename it instead:
-- DO NOT RUN THIS if you just added the 'grams' column above.
-- ALTER TABLE nutrition_logs RENAME COLUMN amount_grams TO grams;

-- 4. Ensure other required columns exist
ALTER TABLE nutrition_logs 
ADD COLUMN IF NOT EXISTS food_name TEXT,
ADD COLUMN IF NOT EXISTS calories DOUBLE PRECISION DEFAULT 0,
ADD COLUMN IF NOT EXISTS protein DOUBLE PRECISION DEFAULT 0,
ADD COLUMN IF NOT EXISTS carbs DOUBLE PRECISION DEFAULT 0,
ADD COLUMN IF NOT EXISTS fats DOUBLE PRECISION DEFAULT 0,
ADD COLUMN IF NOT EXISTS source TEXT,
ADD COLUMN IF NOT EXISTS serving_label TEXT;

-- 5. Create index on logged_at for faster history queries
CREATE INDEX IF NOT EXISTS idx_nutrition_logs_logged_at ON nutrition_logs(logged_at DESC);
