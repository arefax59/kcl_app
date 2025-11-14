-- Script SQL pour ajouter les colonnes de ciblage à la table data
-- Exécutez ce script dans Supabase SQL Editor

-- Ajouter les colonnes pour le ciblage des messages
ALTER TABLE data 
ADD COLUMN IF NOT EXISTS target_group TEXT,
ADD COLUMN IF NOT EXISTS target_user_id TEXT;

-- Ajouter des commentaires pour clarifier l'utilisation
COMMENT ON COLUMN data.target_group IS 'Groupe cible: "chronopost", "dpd", "all", ou NULL pour tous';
COMMENT ON COLUMN data.target_user_id IS 'ID utilisateur spécifique cible, ou NULL pour groupe/tous';

-- Créer un index pour améliorer les performances des requêtes
CREATE INDEX IF NOT EXISTS idx_data_target_group ON data(target_group);
CREATE INDEX IF NOT EXISTS idx_data_target_user_id ON data(target_user_id);

-- Vérifier que les colonnes ont été ajoutées
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'data' 
AND column_name IN ('target_group', 'target_user_id')
ORDER BY column_name;

