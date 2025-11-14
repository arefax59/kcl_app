-- Script SQL pour ajouter la colonne 'group' à la table users
-- Exécutez ce script dans Supabase SQL Editor

-- Ajouter la colonne 'group' si elle n'existe pas
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS "group" TEXT DEFAULT 'admin';

-- Mettre à jour les utilisateurs existants pour avoir 'admin' par défaut
UPDATE users 
SET "group" = 'admin' 
WHERE "group" IS NULL;

-- Créer un index pour améliorer les performances des requêtes par groupe
CREATE INDEX IF NOT EXISTS idx_users_group ON users("group");

-- Vérifier que la colonne a été ajoutée
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'group';

