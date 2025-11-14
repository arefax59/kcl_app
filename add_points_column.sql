-- Script SQL pour ajouter la colonne 'points' à la table users
-- Exécutez ce script dans Supabase SQL Editor

-- Ajouter la colonne 'points' si elle n'existe pas
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS points INTEGER DEFAULT 0;

-- Mettre à jour les utilisateurs existants pour avoir 0 points par défaut
UPDATE users 
SET points = 0 
WHERE points IS NULL;

-- Créer un index pour améliorer les performances des requêtes par points
CREATE INDEX IF NOT EXISTS idx_users_points ON users(points);

-- Vérifier que la colonne a été ajoutée
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'points';

