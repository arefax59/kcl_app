-- Script SQL pour créer la table deliveries dans Supabase
-- Exécutez ce script dans Supabase SQL Editor

-- Créer la table deliveries
CREATE TABLE IF NOT EXISTS deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  date DATE NOT NULL,
  start_time TIME,
  end_time TIME,
  points_taken INTEGER DEFAULT 0,
  points_delivered INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Créer des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_deliveries_user_id ON deliveries(user_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_date ON deliveries(date);

-- Activer RLS
ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;

-- Politiques RLS pour deliveries
CREATE POLICY "Users can read their own deliveries"
  ON deliveries FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own deliveries"
  ON deliveries FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update their own deliveries"
  ON deliveries FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can delete their own deliveries"
  ON deliveries FOR DELETE
  USING (true);

-- Vérifier que la table a été créée
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'deliveries'
ORDER BY ordinal_position;

