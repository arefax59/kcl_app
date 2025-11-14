# 🔧 Guide de Dépannage - Erreur lors de la création d'utilisateur

## 📋 Vérifications à faire

### 1. Vérifier que les tables existent dans Supabase

Allez dans Supabase → **Table Editor** et vérifiez que vous avez :
- ✅ Table `users`
- ✅ Table `data`
- ✅ Table `notifications`

Si les tables n'existent pas, exécutez le script SQL dans `SUPABASE_SETUP.md` (section "Structure de la Base de Données").

### 2. Vérifier les politiques RLS (Row Level Security)

C'est la cause la plus fréquente ! Les politiques RLS peuvent bloquer l'insertion.

**Solution :**
1. Allez dans Supabase → **SQL Editor**
2. Exécutez le script `fix_rls_policies.sql` que j'ai créé
3. Vérifiez que les politiques sont créées :
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'users';
   ```

### 3. Vérifier les logs dans la console Flutter

Quand vous essayez de créer un utilisateur, regardez la console Flutter. Vous devriez voir :
- `📝 Tentative d'insertion utilisateur: [username]`
- `✅ Utilisateur créé avec succès` (si ça marche)
- `❌ Erreur ajout utilisateur: [détails]` (si ça échoue)

### 4. Vérifier la connexion à Supabase

Assurez-vous que :
- ✅ L'URL Supabase est correcte dans `lib/config/supabase_config.dart`
- ✅ La clé anon est correcte
- ✅ Vous avez une connexion internet

### 5. Vérifier le format des données

Les champs requis pour un utilisateur :
- `username` : texte unique
- `password` : sera hashé automatiquement
- `name` : texte
- `email` : texte (format email recommandé)
- `is_admin` : boolean
- `created_at` : timestamp ISO8601
- `fcm_token` : texte (peut être vide)

## 🐛 Messages d'erreur courants

### "Permission refusée. Exécutez le script fix_rls_policies.sql"
**Cause :** Les politiques RLS bloquent l'insertion
**Solution :** Exécutez `fix_rls_policies.sql` dans Supabase SQL Editor

### "Ce nom d'utilisateur existe déjà"
**Cause :** Un utilisateur avec ce username existe déjà
**Solution :** Choisissez un autre nom d'utilisateur

### "La table 'users' n'existe pas"
**Cause :** Les tables n'ont pas été créées
**Solution :** Exécutez le script SQL de création de tables dans `SUPABASE_SETUP.md`

### "Un champ requis est manquant"
**Cause :** Un champ obligatoire n'est pas rempli
**Solution :** Vérifiez que tous les champs sont remplis dans le formulaire

## 🔍 Test rapide

Pour tester si Supabase fonctionne, exécutez ce script dans Supabase SQL Editor :

```sql
-- Tester l'insertion manuelle
INSERT INTO users (username, password, name, email, is_admin, created_at, fcm_token)
VALUES (
  'test_user',
  '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', -- Hash de '123456'
  'Test User',
  'test@example.com',
  false,
  NOW(),
  ''
);

-- Vérifier que l'utilisateur a été créé
SELECT * FROM users WHERE username = 'test_user';

-- Supprimer le test
DELETE FROM users WHERE username = 'test_user';
```

Si ce script fonctionne mais pas l'application, le problème vient des politiques RLS.

## 📞 Besoin d'aide ?

Si le problème persiste, notez :
1. Le message d'erreur exact affiché dans l'application
2. Les logs de la console Flutter
3. Les logs de Supabase (Dashboard → Logs)

