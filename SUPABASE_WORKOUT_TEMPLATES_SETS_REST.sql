-- Add sets/rest metadata to template exercises
ALTER TABLE workout_template_exercises
  ADD COLUMN IF NOT EXISTS sets INT NOT NULL DEFAULT 3;

ALTER TABLE workout_template_exercises
  ADD COLUMN IF NOT EXISTS rest_seconds INT;
