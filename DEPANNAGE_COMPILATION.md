# 🔧 Dépannage des Erreurs de Compilation

## ❌ Erreur : "Process completed with exit code 1"

Cette erreur indique que la compilation a échoué. Voici comment la résoudre :

### Solution 1 : Nettoyer et réinstaller les dépendances

```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Solution 2 : Vérifier la configuration Supabase

Assurez-vous que le fichier `lib/config/supabase_config.dart` existe et contient vos clés :

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'VOTRE_URL';
  static const String supabaseAnonKey = 'VOTRE_CLE';
}
```

### Solution 3 : Vérifier Flutter Doctor

```bash
flutter doctor
```

Résolvez tous les problèmes affichés (marqués avec ❌ ou ⚠️).

### Solution 4 : Vérifier les erreurs spécifiques

Lisez les messages d'erreur complets. Les erreurs courantes sont :

#### Erreur : "Gradle build failed"
- **Cause** : Problème avec la configuration Android
- **Solution** :
  ```bash
  cd android
  ./gradlew clean
  cd ..
  flutter clean
  flutter pub get
  flutter build apk --release
  ```

#### Erreur : "Package not found"
- **Cause** : Dépendance manquante ou mal configurée
- **Solution** :
  ```bash
  flutter pub get
  flutter pub upgrade
  ```

#### Erreur : "MissingPluginException"
- **Cause** : Plugin non correctement configuré
- **Solution** :
  ```bash
  flutter clean
  flutter pub get
  cd android
  ./gradlew clean
  cd ..
  flutter build apk --release
  ```

#### Erreur : "Execution failed for task"
- **Cause** : Problème avec Gradle ou les dépendances Android
- **Solution** :
  1. Vérifiez `android/build.gradle.kts`
  2. Vérifiez `android/app/build.gradle.kts`
  3. Exécutez :
     ```bash
     cd android
     ./gradlew clean
     cd ..
     flutter clean
     flutter pub get
     ```

### Solution 5 : Vérifier les permissions

Sur Windows, assurez-vous que :
- Vous avez les droits d'écriture dans le dossier du projet
- Aucun antivirus ne bloque les fichiers
- Aucun autre processus n'utilise les fichiers (fermez Android Studio, VS Code, etc.)

### Solution 6 : Mettre à jour Flutter

```bash
flutter upgrade
flutter doctor
```

### Solution 7 : Vérifier l'espace disque

Assurez-vous d'avoir au moins 5 Go d'espace libre.

---

## 🛠️ Script de Diagnostic

Utilisez le script `diagnostic_build.bat` pour diagnostiquer automatiquement les problèmes :

```bash
diagnostic_build.bat
```

Ce script va :
1. Vérifier Flutter
2. Vérifier l'environnement
3. Nettoyer le projet
4. Récupérer les dépendances
5. Vérifier la configuration
6. Tester la compilation

---

## 📋 Checklist de Dépannage

- [ ] Flutter est à jour (`flutter upgrade`)
- [ ] Toutes les dépendances sont installées (`flutter pub get`)
- [ ] Le projet est nettoyé (`flutter clean`)
- [ ] `supabase_config.dart` existe et contient les bonnes clés
- [ ] `flutter doctor` ne montre pas d'erreurs critiques
- [ ] Il y a assez d'espace disque
- [ ] Aucun autre processus n'utilise les fichiers
- [ ] Les permissions sont correctes

---

## 🔍 Erreurs Spécifiques

### Erreur : "Could not find or load main class"
- **Solution** : Réinstallez Java JDK

### Erreur : "SDK location not found"
- **Solution** : Créez `android/local.properties` avec :
  ```
  sdk.dir=C:\\Users\\VOTRE_USER\\AppData\\Local\\Android\\Sdk
  ```

### Erreur : "Minimum supported Gradle version"
- **Solution** : Mettez à jour Gradle dans `android/gradle/wrapper/gradle-wrapper.properties`

### Erreur : "Execution failed for task ':app:mergeDebugResources'"
- **Solution** :
  ```bash
  flutter clean
  cd android
  ./gradlew clean
  cd ..
  flutter pub get
  ```

---

## 📞 Obtenir Plus d'Aide

Si le problème persiste :

1. **Exécutez avec plus de détails** :
   ```bash
   flutter build apk --release --verbose
   ```

2. **Vérifiez les logs complets** :
   - Les erreurs détaillées sont affichées dans la console
   - Copiez le message d'erreur complet

3. **Consultez la documentation** :
   - [Flutter Troubleshooting](https://flutter.dev/docs/deployment/android)
   - [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

---

## ✅ Compilation Réussie

Si la compilation réussit, vous trouverez l'APK dans :
- **Debug** : `build/app/outputs/flutter-apk/app-debug.apk`
- **Release** : `build/app/outputs/flutter-apk/app-release.apk`

Pour copier automatiquement dans `releases/`, utilisez `build_apk.bat`.

