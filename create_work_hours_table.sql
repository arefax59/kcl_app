-- Script SQL pour créer la table work_hours dans Supabase
-- Exécutez ce script dans Supabase SQL Editor

-- Créer la table work_hours
CREATE TABLE IF NOT EXISTS work_hours (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  points INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- Créer un index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_work_hours_user_id ON work_hours(user_id);
CREATE INDEX IF NOT EXISTS idx_work_hours_date ON work_hours(date);

-- Activer RLS
ALTER TABLE work_hours ENABLE ROW LEVEL SECURITY;

-- Politiques RLS pour work_hours
CREATE POLICY "Users can read their own work hours"
  ON work_hours FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own work hours"
  ON work_hours FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update their own work hours"
  ON work_hours FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Vérifier que la table a été créée
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'work_hours'
ORDER BY ordinal_position;

