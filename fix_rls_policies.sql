-- Script SQL pour corriger les politiques RLS dans Supabase
-- Exécutez ce script dans Supabase SQL Editor si vous avez des erreurs de permission

-- 1. Désactiver temporairement RLS pour tester (DÉCONSEILLÉ EN PRODUCTION)
-- ALTER TABLE users DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE data DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

-- 2. OU Configurer les politiques RLS correctement (RECOMMANDÉ)

-- Supprimer les anciennes politiques si elles existent
DROP POLICY IF EXISTS "Users can read all users" ON users;
DROP POLICY IF EXISTS "Only admins can insert users" ON users;
DROP POLICY IF EXISTS "Everyone can read data" ON data;
DROP POLICY IF EXISTS "Authenticated users can insert data" ON data;
DROP POLICY IF EXISTS "Everyone can read notifications" ON notifications;
DROP POLICY IF EXISTS "Admins can insert notifications" ON notifications;

-- Activer RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE data ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Politiques pour la table users
-- Permettre à tous de lire les utilisateurs
CREATE POLICY "Users can read all users"
  ON users FOR SELECT
  USING (true);

-- Permettre à tous d'insérer des utilisateurs (pour la création par l'admin)
-- En production, vous pourriez vouloir restreindre cela
CREATE POLICY "Anyone can insert users"
  ON users FOR INSERT
  WITH CHECK (true);

-- Permettre à tous de mettre à jour les utilisateurs
CREATE POLICY "Anyone can update users"
  ON users FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Permettre à tous de supprimer les utilisateurs
CREATE POLICY "Anyone can delete users"
  ON users FOR DELETE
  USING (true);

-- Politiques pour la table data
-- Permettre à tous de lire les données
CREATE POLICY "Everyone can read data"
  ON data FOR SELECT
  USING (true);

-- Permettre à tous d'insérer des données
CREATE POLICY "Anyone can insert data"
  ON data FOR INSERT
  WITH CHECK (true);

-- Permettre à tous de mettre à jour les données
CREATE POLICY "Anyone can update data"
  ON data FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Permettre à tous de supprimer les données
CREATE POLICY "Anyone can delete data"
  ON data FOR DELETE
  USING (true);

-- Politiques pour la table notifications
-- Permettre à tous de lire les notifications
CREATE POLICY "Everyone can read notifications"
  ON notifications FOR SELECT
  USING (true);

-- Permettre à tous d'insérer des notifications
CREATE POLICY "Anyone can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (true);

-- Permettre à tous de mettre à jour les notifications
CREATE POLICY "Anyone can update notifications"
  ON notifications FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Vérifier que les politiques sont créées
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename IN ('users', 'data', 'notifications')
ORDER BY tablename, policyname;

