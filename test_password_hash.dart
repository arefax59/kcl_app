// Script de test pour vérifier le hachage des mots de passe
// Exécutez avec: dart test_password_hash.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';

String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

void main() {
  print('═══════════════════════════════════════');
  print('Test de hachage de mot de passe');
  print('═══════════════════════════════════════');
  print('');
  
  // Test avec différents mots de passe
  final testPasswords = ['123456', 'test123', 'password123'];
  
  for (var password in testPasswords) {
    final hash = hashPassword(password);
    print('Mot de passe: $password');
    print('Hash SHA256: $hash');
    print('---');
  }
  
  print('');
  print('Pour tester un mot de passe spécifique:');
  print('Modifiez la variable testPasswords dans ce script');
}

