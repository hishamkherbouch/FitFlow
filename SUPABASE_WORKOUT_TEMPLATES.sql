-- Workout templates and exercise mapping
CREATE TABLE IF NOT EXISTS workout_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  title TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS workout_template_exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES workout_templates(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE RESTRICT,
  position INT NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS workout_templates_user_id_idx
  ON workout_templates(user_id);

CREATE INDEX IF NOT EXISTS workout_template_exercises_template_idx
  ON workout_template_exercises(template_id);

ALTER TABLE workout_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_template_exercises ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own templates" ON workout_templates;
CREATE POLICY "Users can manage own templates"
  ON workout_templates
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own template exercises" ON workout_template_exercises;
CREATE POLICY "Users can manage own template exercises"
  ON workout_template_exercises
  USING (
    EXISTS (
      SELECT 1
      FROM workout_templates t
      WHERE t.id = workout_template_exercises.template_id
        AND t.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM workout_templates t
      WHERE t.id = workout_template_exercises.template_id
        AND t.user_id = auth.uid()
    )
  );
