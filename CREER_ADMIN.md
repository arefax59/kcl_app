# 👤 Créer l'utilisateur Admin

## Méthode 1 : Automatique (Recommandée)

L'application crée automatiquement l'utilisateur admin au premier lancement si les tables existent dans Supabase.

**Identifiants par défaut :**
- **Username** : `adminkcl`
- **Password** : `123456`

⚠️ **Important** : Changez ce mot de passe après la première connexion !

## Méthode 2 : Manuel (via SQL)

Si vous préférez créer l'admin manuellement, exécutez ce script SQL dans Supabase :

```sql
-- Insérer l'utilisateur admin
-- Le mot de passe sera hashé automatiquement par l'application
INSERT INTO users (username, password, name, email, is_admin, created_at, fcm_token)
VALUES (
  'adminkcl',
  'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', -- Hash SHA256 de '123456'
  'Administrateur KCL',
  'admin@kcl.com',
  true,
  NOW(),
  ''
);
```

### Pour générer le hash d'un mot de passe personnalisé :

Vous pouvez utiliser ce script Dart pour générer le hash :

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  String password = 'votre_mot_de_passe';
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  print('Hash: ${digest.toString()}');
}
```

## Méthode 3 : Via l'application (si vous avez déjà un admin)

Si vous avez déjà un compte admin, vous pouvez créer d'autres admins via l'écran d'administration de l'application.

## Vérifier que l'admin existe

Exécutez cette requête dans Supabase SQL Editor :

```sql
SELECT * FROM users WHERE username = 'adminkcl';
```

Si l'admin existe, vous verrez ses informations. Sinon, la requête retournera un résultat vide.

