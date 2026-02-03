-- Fix for missing 'source' and 'serving_label' columns

-- 1. Add 'source' column
ALTER TABLE nutrition_logs 
ADD COLUMN IF NOT EXISTS source TEXT;

-- 2. Add 'serving_label' column (likely missing too)
ALTER TABLE nutrition_logs 
ADD COLUMN IF NOT EXISTS serving_label TEXT;

-- 3. Ensure other columns are present (just in case)
ALTER TABLE nutrition_logs 
ADD COLUMN IF NOT EXISTS grams DOUBLE PRECISION DEFAULT 0,
ADD COLUMN IF NOT EXISTS logged_at TIMESTAMPTZ DEFAULT NOW();
