import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:math';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'kcl_database.db');
    return await openDatabase(
      path,
      version: 2, // Version augmentée pour la migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table utilisateurs avec authentification
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        is_admin INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Table données
    await db.execute('''
      CREATE TABLE data(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT,
        user_id INTEGER,
        synced INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Créer l'utilisateur admin par défaut
    await db.insert('users', {
      'username': 'adminkcl',
      'password': '123456',
      'name': 'Administrateur KCL',
      'email': 'admin@kcl.com',
      'is_admin': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration : supprimer l'ancienne table et recréer
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('DROP TABLE IF EXISTS data');

      // Recréer les tables
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          is_admin INTEGER DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE data(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT,
          user_id INTEGER,
          synced INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');

      // Créer l'admin
      await db.insert('users', {
        'username': 'adminkcl',
        'password': '123456',
        'name': 'Administrateur KCL',
        'email': 'admin@kcl.com',
        'is_admin': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Générer un mot de passe aléatoire de 8 chiffres
  String generatePassword() {
    final random = Random();
    String password = '';
    for (int i = 0; i < 8; i++) {
      password += random.nextInt(10).toString();
    }
    return password;
  }

  // Authentifier un utilisateur
  Future<Map<String, dynamic>?> authenticateUser(String username, String password) async {
    Database db = await database;
    final results = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // Vérifier si un utilisateur est admin
  Future<bool> isAdmin(String username) async {
    Database db = await database;
    final results = await db.query(
      'users',
      where: 'username = ? AND is_admin = 1',
      whereArgs: [username],
    );
    return results.isNotEmpty;
  }

  // Ajouter un utilisateur
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.insert('users', user);
  }

  // Récupérer tous les utilisateurs
  Future<List<Map<String, dynamic>>> getUsers() async {
    Database db = await database;
    return await db.query('users', orderBy: 'created_at DESC');
  }

  // Récupérer un utilisateur par ID
  Future<Map<String, dynamic>?> getUserById(int id) async {
    Database db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // Récupérer un utilisateur par username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    Database db = await database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // Mettre à jour un utilisateur
  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    Database db = await database;
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Supprimer un utilisateur
  Future<int> deleteUser(int id) async {
    Database db = await database;
    // Supprimer aussi ses données
    await db.delete('data', where: 'user_id = ?', whereArgs: [id]);
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // Ajouter des données
  Future<int> insertData(Map<String, dynamic> data) async {
    Database db = await database;
    return await db.insert('data', data);
  }

  // Récupérer toutes les données
  Future<List<Map<String, dynamic>>> getAllData() async {
    Database db = await database;
    return await db.query('data', orderBy: 'created_at DESC');
  }

  // Récupérer les données d'un utilisateur
  Future<List<Map<String, dynamic>>> getDataByUser(int userId) async {
    Database db = await database;
    return await db.query(
      'data',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  // Mettre à jour le statut de synchronisation
  Future<int> updateSyncStatus(int id, int synced) async {
    Database db = await database;
    return await db.update(
      'data',
      {'synced': synced},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Supprimer toutes les données (pour réinitialisation)
  Future<void> deleteAllData() async {
    Database db = await database;
    await db.delete('data');
  }
}