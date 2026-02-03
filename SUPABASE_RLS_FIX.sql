-- Fix for Row-Level Security (RLS) policies on nutrition_logs table

-- 1. Enable RLS (in case it wasn't enabled)
ALTER TABLE nutrition_logs ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies to ensure clean state
DROP POLICY IF EXISTS "Users can view own logs" ON nutrition_logs;
DROP POLICY IF EXISTS "Users can insert own logs" ON nutrition_logs;
DROP POLICY IF EXISTS "Users can update own logs" ON nutrition_logs;
DROP POLICY IF EXISTS "Users can delete own logs" ON nutrition_logs;

-- 3. Recreate policies

-- Allow users to view their own logs
CREATE POLICY "Users can view own logs"
  ON nutrition_logs FOR SELECT
  USING (auth.uid() = user_id);

-- Allow users to insert their own logs
-- Critical: This policy allows the INSERT if the user_id in the row matches the authenticated user
CREATE POLICY "Users can insert own logs"
  ON nutrition_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own logs
CREATE POLICY "Users can update own logs"
  ON nutrition_logs FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Allow users to delete their own logs
CREATE POLICY "Users can delete own logs"
  ON nutrition_logs FOR DELETE
  USING (auth.uid() = user_id);
