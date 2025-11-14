# 🚀 Guide d'Intégration Supabase pour KCL App

## 📋 Prérequis

1. Créer un compte sur [Supabase](https://supabase.com)
2. Créer un nouveau projet
3. Noter votre URL de projet et la clé API (anon key)

## 📦 Installation

### 1. Ajouter les dépendances

Ajoutez dans `pubspec.yaml` :

```yaml
dependencies:
  # Supabase
  supabase_flutter: ^2.5.0
  
  # Pour le hachage de mot de passe (sécurité)
  crypto: ^3.0.3
```

Puis exécutez :
```bash
flutter pub get
```

### 2. Configuration Supabase

Créez un fichier `lib/config/supabase_config.dart` :

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'VOTRE_URL_SUPABASE';
  static const String supabaseAnonKey = 'VOTRE_CLE_ANON';
}
```

⚠️ **Important** : Ne commitez jamais ce fichier avec vos vraies clés ! Ajoutez-le au `.gitignore`.

## 🗄️ Structure de la Base de Données

### Tables à créer dans Supabase SQL Editor

```sql
-- Table des utilisateurs
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL, -- En production, utilisez Supabase Auth
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  is_admin BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  fcm_token TEXT
);

-- Table des données
CREATE TABLE data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  from_admin BOOLEAN DEFAULT FALSE
);

-- Table des notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data_id UUID REFERENCES data(id) ON DELETE SET NULL,
  type TEXT DEFAULT 'general',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  sent_to_all BOOLEAN DEFAULT FALSE,
  read_by UUID[] DEFAULT ARRAY[]::UUID[]
);

-- Index pour améliorer les performances
CREATE INDEX idx_data_user_id ON data(user_id);
CREATE INDEX idx_data_created_at ON data(created_at DESC);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
```

### Politiques de Sécurité (Row Level Security)

```sql
-- Activer RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE data ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Politiques pour users (lecture pour tous, écriture pour admins)
CREATE POLICY "Users can read all users"
  ON users FOR SELECT
  USING (true);

CREATE POLICY "Only admins can insert users"
  ON users FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Politiques pour data (lecture pour tous, écriture pour utilisateurs connectés)
CREATE POLICY "Everyone can read data"
  ON data FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert data"
  ON data FOR INSERT
  WITH CHECK (true);

-- Politiques pour notifications (lecture pour tous)
CREATE POLICY "Everyone can read notifications"
  ON notifications FOR SELECT
  USING (true);

CREATE POLICY "Admins can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND is_admin = true
    )
  );
```

## 🔧 Service Supabase

Créez `lib/services/supabase_service.dart` :

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Initialiser Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'VOTRE_URL_SUPABASE',
      anonKey: 'VOTRE_CLE_ANON',
    );
  }

  // Générer un mot de passe aléatoire
  String generatePassword() {
    final random = Random();
    String password = '';
    for (int i = 0; i < 8; i++) {
      password += random.nextInt(10).toString();
    }
    return password;
  }

  // Hacher un mot de passe (pour la sécurité)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Authentifier un utilisateur
  Future<Map<String, dynamic>?> authenticateUser(
    String username,
    String password,
  ) async {
    try {
      final hashedPassword = _hashPassword(password);
      final response = await _supabase
          .from('users')
          .select()
          .eq('username', username)
          .eq('password', hashedPassword)
          .maybeSingle();

      if (response != null) {
        return {
          'id': response['id'],
          'username': response['username'],
          'name': response['name'],
          'email': response['email'],
          'is_admin': response['is_admin'],
        };
      }
      return null;
    } catch (e) {
      print('Erreur d\'authentification: $e');
      return null;
    }
  }

  // Ajouter un utilisateur
  Future<String> insertUser(Map<String, dynamic> user) async {
    try {
      final userData = Map<String, dynamic>.from(user);
      userData['password'] = _hashPassword(user['password'] as String);
      
      final response = await _supabase
          .from('users')
          .insert(userData)
          .select()
          .single();
      
      return response['id'] as String;
    } catch (e) {
      print('Erreur ajout utilisateur: $e');
      rethrow;
    }
  }

  // Récupérer tous les utilisateurs (stream temps réel)
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => item as Map<String, dynamic>).toList());
  }

  // Mettre à jour un utilisateur
  Future<void> updateUser(String id, Map<String, dynamic> updates) async {
    try {
      if (updates.containsKey('password')) {
        updates['password'] = _hashPassword(updates['password'] as String);
      }
      await _supabase.from('users').update(updates).eq('id', id);
    } catch (e) {
      print('Erreur mise à jour utilisateur: $e');
      rethrow;
    }
  }

  // Supprimer un utilisateur
  Future<void> deleteUser(String id) async {
    try {
      // Supprimer les données associées
      await _supabase.from('data').delete().eq('user_id', id);
      // Supprimer l'utilisateur
      await _supabase.from('users').delete().eq('id', id);
    } catch (e) {
      print('Erreur suppression utilisateur: $e');
      rethrow;
    }
  }

  // Ajouter des données
  Future<String> insertData(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('data')
          .insert(data)
          .select()
          .single();
      
      return response['id'] as String;
    } catch (e) {
      print('Erreur ajout données: $e');
      rethrow;
    }
  }

  // Récupérer toutes les données (stream temps réel)
  Stream<List<Map<String, dynamic>>> getAllDataStream() {
    return _supabase
        .from('data')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => item as Map<String, dynamic>).toList());
  }

  // Envoyer une notification
  Future<void> sendNotificationToAllUsers({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? dataId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'title': title,
        'body': body,
        'data': data ?? {},
        'data_id': dataId,
        'type': dataId != null ? 'new_data' : 'general',
        'sent_to_all': true,
      });
    } catch (e) {
      print('Erreur envoi notification: $e');
      rethrow;
    }
  }

  // Stream des notifications
  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => data.map((item) => item as Map<String, dynamic>).toList());
  }

  // Mettre à jour le token FCM
  Future<void> updateUserFcmToken(String userId, String fcmToken) async {
    try {
      await _supabase
          .from('users')
          .update({'fcm_token': fcmToken})
          .eq('id', userId);
    } catch (e) {
      print('Erreur mise à jour token FCM: $e');
    }
  }
}
```

## 🔄 Migration depuis Firebase

1. Remplacez `FirebaseService` par `SupabaseService` dans tous les fichiers
2. Initialisez Supabase dans `main.dart` :

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Supabase
  await SupabaseService.initialize();
  
  runApp(const MyApp());
}
```

## ✅ Avantages de Supabase

- ✅ **Open-source** : Vous pouvez auto-héberger si besoin
- ✅ **Gratuit** : Plan gratuit généreux (500 MB base, 2 GB bande passante)
- ✅ **Temps réel** : Synchronisation automatique
- ✅ **Sécurité** : Row Level Security intégré
- ✅ **PostgreSQL** : Base de données relationnelle puissante
- ✅ **API REST** : Accès direct à votre base de données

## 📚 Ressources

- Documentation Supabase : https://supabase.com/docs
- Package Flutter : https://pub.dev/packages/supabase_flutter
- Exemples : https://github.com/supabase/supabase-flutter

