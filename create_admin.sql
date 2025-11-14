-- Script SQL pour créer l'utilisateur admin dans Supabase
-- Exécutez ce script dans Supabase SQL Editor

-- Hash SHA256 du mot de passe "123456"
-- Vous pouvez changer le mot de passe en générant un nouveau hash

INSERT INTO users (username, password, name, email, is_admin, created_at, fcm_token)
VALUES (
  'adminkcl',
  '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', -- Hash SHA256 de '123456'
  'Administrateur KCL',
  'admin@kcl.com',
  true,
  NOW(),
  ''
)
ON CONFLICT (username) DO NOTHING; -- Ne fait rien si l'utilisateur existe déjà

-- Vérifier que l'admin a été créé
SELECT username, name, email, is_admin, created_at 
FROM users 
WHERE username = 'adminkcl';

