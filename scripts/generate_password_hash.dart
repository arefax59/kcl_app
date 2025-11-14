// Script pour générer le hash SHA256 d'un mot de passe
// Exécutez avec: dart scripts/generate_password_hash.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  // Changez ce mot de passe selon vos besoins
  String password = '123456';
  
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  
  print('═══════════════════════════════════════');
  print('Génération du hash de mot de passe');
  print('═══════════════════════════════════════');
  print('Mot de passe: $password');
  print('Hash SHA256: ${digest.toString()}');
  print('═══════════════════════════════════════');
  print('');
  print('Copiez ce hash dans le script SQL create_admin.sql');
}

