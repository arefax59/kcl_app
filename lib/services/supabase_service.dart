import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Initialiser Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  // Getter pour accéder au client Supabase
  SupabaseClient get _supabase => Supabase.instance.client;

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
      print('🔐 Tentative d\'authentification pour: $username');
      final hashedPassword = _hashPassword(password);
      print('   Hash du mot de passe: $hashedPassword');
      
      // D'abord, vérifier si l'utilisateur existe
      final userCheck = await _supabase
          .from('users')
          .select('username, password')
          .eq('username', username)
          .maybeSingle();
      
      if (userCheck == null) {
        print('❌ Utilisateur "$username" non trouvé');
        return null;
      }
      
      print('   Hash stocké dans la DB: ${userCheck['password']}');
      print('   Hash calculé: $hashedPassword');
      print('   Hashs identiques: ${userCheck['password'] == hashedPassword}');
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('username', username)
          .eq('password', hashedPassword)
          .maybeSingle();

      if (response != null) {
        print('✅ Authentification réussie pour: $username');
        return {
          'id': response['id'],
          'username': response['username'],
          'name': response['name'],
          'email': response['email'],
          'is_admin': response['is_admin'],
          'group': response['group'] ?? 'admin',
          'points': response['points'] ?? 0,
        };
      } else {
        print('❌ Mot de passe incorrect pour: $username');
      }
      return null;
    } catch (e) {
      print('❌ Erreur d\'authentification: $e');
      return null;
    }
  }

  // Ajouter un utilisateur
  Future<String> insertUser(Map<String, dynamic> user) async {
    try {
      final userData = Map<String, dynamic>.from(user);
      
      // S'assurer que le mot de passe est hashé
      if (userData.containsKey('password') && userData['password'] is String) {
        userData['password'] = _hashPassword(userData['password'] as String);
      }
      
      // Préparer les données pour l'insertion
      final dataToInsert = {
        'username': userData['username'],
        'password': userData['password'],
        'name': userData['name'],
        'email': userData['email'],
        'is_admin': userData['is_admin'] ?? false,
        'group': userData['group'] ?? 'admin',
        'points': userData['points'] ?? 0,
        'created_at': userData['created_at'] ?? DateTime.now().toIso8601String(),
        'fcm_token': userData['fcm_token'] ?? '',
      };
      
      print('📝 Tentative d\'insertion utilisateur: ${dataToInsert['username']}');
      print('   Mot de passe original: ${user['password']}');
      print('   Mot de passe hashé: ${dataToInsert['password']}');
      print('   Données complètes: ${dataToInsert.toString()}');
      
      final response = await _supabase
          .from('users')
          .insert(dataToInsert)
          .select()
          .single();
      
      print('✅ Utilisateur créé avec succès: ${response['id']}');
      return response['id'] as String;
    } catch (e, stackTrace) {
      print('❌ Erreur ajout utilisateur: $e');
      print('   Stack trace: $stackTrace');
      print('   Données envoyées: $user');
      
      // Message d'erreur plus détaillé
      String errorMessage = 'Erreur lors de la création de l\'utilisateur';
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('duplicate key') || errorString.contains('unique constraint')) {
        errorMessage = 'Ce nom d\'utilisateur existe déjà. Veuillez en choisir un autre.';
      } else if (errorString.contains('permission denied') || 
                 errorString.contains('rls') || 
                 errorString.contains('row-level security')) {
        errorMessage = 'Permission refusée. Exécutez le script fix_rls_policies.sql dans Supabase';
      } else if (errorString.contains('relation') && errorString.contains('does not exist')) {
        errorMessage = 'La table "users" n\'existe pas. Créez-la avec le script SQL dans SUPABASE_SETUP.md';
      } else if (errorString.contains('null value') || errorString.contains('not-null constraint')) {
        errorMessage = 'Un champ requis est manquant ou invalide';
      } else if (errorString.contains('invalid input syntax')) {
        errorMessage = 'Format de données invalide. Vérifiez les champs (email, etc.)';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        errorMessage = 'Erreur de connexion. Vérifiez votre connexion internet';
      }
      
      print('   Message d\'erreur: $errorMessage');
      throw Exception(errorMessage);
    }
  }

  // Récupérer tous les utilisateurs (stream temps réel)
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => Map<String, dynamic>.from(item)).toList());
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
        .map((data) => data.map((item) => Map<String, dynamic>.from(item)).toList());
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
        .map((data) => data.map((item) => Map<String, dynamic>.from(item)).toList());
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

  // Gestion des horaires de travail
  Future<void> saveWorkHours(String userId, String startTime, String endTime, String date, int points) async {
    try {
      // Vérifier si des horaires existent déjà pour cette date
      final existing = await _supabase
          .from('work_hours')
          .select()
          .eq('user_id', userId)
          .eq('date', date)
          .maybeSingle();

      if (existing != null) {
        // Mettre à jour
        await _supabase
            .from('work_hours')
            .update({
              'start_time': startTime,
              'end_time': endTime,
              'points': points,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      } else {
        // Créer
        await _supabase.from('work_hours').insert({
          'user_id': userId,
          'date': date,
          'start_time': startTime,
          'end_time': endTime,
          'points': points,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Erreur sauvegarde horaires: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getWorkHours(String userId, String date) async {
    try {
      final response = await _supabase
          .from('work_hours')
          .select()
          .eq('user_id', userId)
          .eq('date', date)
          .maybeSingle();
      
      if (response != null) {
        return Map<String, dynamic>.from(response);
      }
      return null;
    } catch (e) {
      print('Erreur récupération horaires: $e');
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> getWorkHoursStream(String userId) {
    return _supabase
        .from('work_hours')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(30)
        .map((data) => data.map((item) => Map<String, dynamic>.from(item)).toList());
  }

  // Récupérer les informations envoyées par l'admin (filtrées selon le groupe de l'utilisateur)
  Stream<List<Map<String, dynamic>>> getAdminMessagesStream([String? userGroup, String? userId]) {
    return _supabase
        .from('data')
        .stream(primaryKey: ['id'])
        .eq('from_admin', true)
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) {
          // Filtrer les messages selon le groupe de l'utilisateur et les cibles
          return data.where((item) {
            final targetGroup = item['target_group'] as String?;
            final targetUserId = item['target_user_id'] as String?;
            
            // Si pas de cible spécifiée, le message est pour tous
            if (targetGroup == null && targetUserId == null) {
              return true;
            }
            
            // Si ciblé pour un utilisateur spécifique
            if (targetUserId != null && userId != null) {
              return targetUserId == userId;
            }
            
            // Si ciblé pour un groupe
            if (targetGroup != null) {
              if (targetGroup == 'all') {
                return true; // Message pour tous
              }
              if (userGroup != null && targetGroup == userGroup) {
                return true; // Message pour le groupe de l'utilisateur
              }
            }
            
            return false;
          }).map((item) => Map<String, dynamic>.from(item)).toList();
        });
  }

  // Gestion des livraisons
  Future<String> insertDelivery(Map<String, dynamic> delivery) async {
    try {
      final response = await _supabase
          .from('deliveries')
          .insert(delivery)
          .select()
          .single();
      
      return response['id'] as String;
    } catch (e) {
      print('Erreur ajout livraison: $e');
      rethrow;
    }
  }

  Future<void> updateDelivery(String id, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _supabase
          .from('deliveries')
          .update(updates)
          .eq('id', id);
    } catch (e) {
      print('Erreur mise à jour livraison: $e');
      rethrow;
    }
  }

  Future<void> deleteDelivery(String id) async {
    try {
      await _supabase
          .from('deliveries')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Erreur suppression livraison: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getDeliveriesStream(String userId, int year, int month) {
    return _supabase
        .from('deliveries')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) {
          // Filtrer par user_id, année et mois côté client
          return data
              .where((item) {
                if (item['user_id'] != userId) return false;
                if (item['date'] == null) return false;
                final itemDate = DateTime.parse(item['date'] as String);
                return itemDate.year == year && itemDate.month == month;
              })
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        });
  }

  // Gestion des points
  Future<void> updateUserPoints(String userId, int points) async {
    try {
      await _supabase
          .from('users')
          .update({'points': points})
          .eq('id', userId);
    } catch (e) {
      print('Erreur mise à jour points: $e');
      rethrow;
    }
  }

  Future<void> addPoints(String userId, int pointsToAdd) async {
    try {
      // Récupérer les points actuels
      final user = await _supabase
          .from('users')
          .select('points')
          .eq('id', userId)
          .single();
      
      final currentPoints = (user['points'] as int? ?? 0);
      final newPoints = currentPoints + pointsToAdd;
      
      await _supabase
          .from('users')
          .update({'points': newPoints})
          .eq('id', userId);
    } catch (e) {
      print('Erreur ajout points: $e');
      rethrow;
    }
  }

  Future<int> getUserPoints(String userId) async {
    try {
      final user = await _supabase
          .from('users')
          .select('points')
          .eq('id', userId)
          .single();
      
      return user['points'] as int? ?? 0;
    } catch (e) {
      print('Erreur récupération points: $e');
      return 0;
    }
  }

  // Initialiser l'utilisateur admin par défaut
  Future<void> initializeAdminUser() async {
    try {
      // Vérifier si l'admin existe déjà
      final adminExists = await getUserByUsername('adminkcl');
      if (adminExists == null) {
        // Créer l'utilisateur admin
        await insertUser({
          'username': 'adminkcl',
          'password': '123456', // Mot de passe par défaut (sera hashé automatiquement)
          'name': 'Administrateur KCL',
          'email': 'admin@kcl.com',
          'is_admin': true,
          'group': 'admin',
          'created_at': DateTime.now().toIso8601String(),
          'fcm_token': '',
        });
        print('✅ Utilisateur admin créé avec succès');
        print('   Username: adminkcl');
        print('   Password: 123456');
        print('   ⚠️ Changez ce mot de passe après la première connexion !');
      } else {
        print('ℹ️ L\'utilisateur admin existe déjà');
      }
    } catch (e) {
      print('❌ Erreur initialisation admin: $e');
      rethrow;
    }
  }

  // Récupérer un utilisateur par username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();
      
      if (response != null) {
        return Map<String, dynamic>.from(response);
      }
      return null;
    } catch (e) {
      print('Erreur récupération utilisateur: $e');
      return null;
    }
  }
}