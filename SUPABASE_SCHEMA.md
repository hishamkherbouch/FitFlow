# Supabase Schema Setup for FitFlow

## Required Table: `nutrition_logs`

Run this SQL in your Supabase SQL Editor to create the correct table structure:

```sql
-- Drop the table if it exists to start fresh (WARNING: This deletes all data!)
-- DROP TABLE IF EXISTS nutrition_logs;

CREATE TABLE IF NOT EXISTS nutrition_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  food_name TEXT NOT NULL,
  source TEXT,
  grams DOUBLE PRECISION NOT NULL,
  serving_label TEXT,
  calories DOUBLE PRECISION NOT NULL,
  protein DOUBLE PRECISION NOT NULL,
  carbs DOUBLE PRECISION NOT NULL,
  fats DOUBLE PRECISION NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_nutrition_logs_user_date ON nutrition_logs(user_id, logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_nutrition_logs_logged_at ON nutrition_logs(logged_at DESC);

-- Row Level Security (RLS) policies
ALTER TABLE nutrition_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own logs
CREATE POLICY "Users can view own logs"
  ON nutrition_logs FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own logs
CREATE POLICY "Users can insert own logs"
  ON nutrition_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own logs
CREATE POLICY "Users can update own logs"
  ON nutrition_logs FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own logs
CREATE POLICY "Users can delete own logs"
  ON nutrition_logs FOR DELETE
  USING (auth.uid() = user_id);
```

## Enable Anonymous Authentication

In your Supabase dashboard:
1. Go to Authentication > Providers
2. Enable "Anonymous" provider
3. Save changes
