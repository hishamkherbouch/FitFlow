-- Exercise catalog table for workout templates
CREATE TABLE IF NOT EXISTS exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  equipment TEXT NOT NULL,
  target_muscle TEXT NOT NULL,
  body_part TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS exercises_name_unique
  ON exercises (name);

ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read exercises" ON exercises;
DROP POLICY IF EXISTS "Public insert exercises" ON exercises;

CREATE POLICY "Public read exercises"
  ON exercises FOR SELECT
  USING (true);

CREATE POLICY "Public insert exercises"
  ON exercises FOR INSERT
  WITH CHECK (true);
