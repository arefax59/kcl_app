-- Script SQL pour ajouter la colonne 'points' à la table work_hours
-- Exécutez ce script dans Supabase SQL Editor si la table existe déjà

-- Ajouter la colonne 'points' si elle n'existe pas
ALTER TABLE work_hours 
ADD COLUMN IF NOT EXISTS points INTEGER DEFAULT 0;

-- Mettre à jour les horaires existants pour avoir 0 points par défaut
UPDATE work_hours 
SET points = 0 
WHERE points IS NULL;

-- Vérifier que la colonne a été ajoutée
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'work_hours' AND column_name = 'points';

