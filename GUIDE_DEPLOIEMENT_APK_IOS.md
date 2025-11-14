# Guide de Déploiement - APK Android et iOS

Ce guide vous explique comment générer l'APK pour Android et l'IPA pour iOS.

## 📱 Android - Génération de l'APK

### Méthode 1 : Script automatique (Windows)

1. **Double-cliquez sur `build_apk.bat`**
2. Choisissez le type d'APK :
   - **Debug** : Pour tester l'application
   - **Release** : Pour la production (recommandé)
3. L'APK sera généré dans :
   - `build/app/outputs/flutter-apk/app-release.apk`
   - `releases/kcl_app_release.apk` (copie automatique)

### Méthode 2 : Ligne de commande

```bash
# Nettoyer le projet
flutter clean

# Récupérer les dépendances
flutter pub get

# Générer l'APK Release
flutter build apk --release

# L'APK sera dans : build/app/outputs/flutter-apk/app-release.apk
```

### Installation sur Android

1. **Transférer l'APK** sur votre téléphone Android :
   - Par USB : copiez `releases/kcl_app_release.apk` sur votre téléphone
   - Par email : envoyez-vous l'APK par email
   - Par cloud : utilisez Google Drive, Dropbox, etc.

2. **Activer l'installation depuis des sources inconnues** :
   - Allez dans **Paramètres** > **Sécurité**
   - Activez **"Sources inconnues"** ou **"Installer des applications inconnues"**

3. **Installer l'APK** :
   - Ouvrez le fichier APK sur votre téléphone
   - Suivez les instructions d'installation

### Générer un APK split par architecture (optionnel)

Pour réduire la taille de l'APK, vous pouvez générer des APK séparés :

```bash
flutter build apk --split-per-abi
```

Cela créera :
- `app-armeabi-v7a-release.apk` (32-bit)
- `app-arm64-v8a-release.apk` (64-bit)
- `app-x86_64-release.apk` (x86_64)

## 🍎 iOS - Génération de l'IPA

**⚠️ IMPORTANT :** La génération d'un IPA signé nécessite :
- Un **Mac** avec **macOS**
- **Xcode** installé
- Un **compte développeur Apple** (gratuit ou payant)
- Un **certificat de signature** configuré

### Méthode 1 : Via Xcode (Recommandé)

1. **Ouvrir le projet dans Xcode** :
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Configurer le projet** :
   - Sélectionnez le projet **Runner** dans le navigateur
   - Allez dans l'onglet **Signing & Capabilities**
   - Sélectionnez votre **Team** (votre compte Apple)
   - Xcode générera automatiquement les certificats

3. **Sélectionner la destination** :
   - Dans la barre d'outils, sélectionnez **"Any iOS Device"** ou votre iPhone connecté

4. **Archiver l'application** :
   - Menu **Product** > **Archive**
   - Attendez la fin de l'archivage

5. **Distribuer l'application** :
   - Dans la fenêtre **Organizer**, cliquez sur **"Distribute App"**
   - Choisissez une méthode :
     - **Ad Hoc** : Pour installer sur des appareils spécifiques (jusqu'à 100)
     - **App Store Connect** : Pour publier sur l'App Store
     - **Development** : Pour tester sur votre appareil

6. **Exporter l'IPA** :
   - Suivez les instructions de l'assistant
   - L'IPA sera exporté dans le dossier que vous choisissez

### Méthode 2 : Ligne de commande (Build non signé)

```bash
# Nettoyer le projet
flutter clean

# Récupérer les dépendances
flutter pub get

# Générer l'IPA (non signé)
flutter build ios --release --no-codesign
```

**Note :** Cet IPA ne pourra pas être installé sur un appareil réel sans signature.

### Installation sur iPhone (Ad Hoc)

1. **Obtenir l'IPA** depuis Xcode (méthode Ad Hoc)

2. **Installer via iTunes/Finder** :
   - Connectez votre iPhone au Mac
   - Ouvrez **Finder** (ou iTunes sur macOS Mojave et antérieur)
   - Sélectionnez votre iPhone
   - Glissez-déposez l'IPA dans la section **Apps**

3. **Installer via TestFlight** (recommandé) :
   - Téléversez l'IPA sur **App Store Connect**
   - Ajoutez les testeurs dans **TestFlight**
   - Les testeurs recevront une invitation par email

### Installation via TestFlight

1. **Créer un compte App Store Connect** :
   - Allez sur [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Créez un compte développeur (99$/an) ou utilisez un compte existant

2. **Créer une nouvelle app** :
   - Cliquez sur **"My Apps"** > **"+"**
   - Remplissez les informations de l'application

3. **Téléverser l'IPA** :
   - Utilisez **Transporter** ou **Xcode** pour téléverser
   - Attendez la validation (peut prendre quelques heures)

4. **Ajouter des testeurs** :
   - Allez dans **TestFlight**
   - Ajoutez les emails des testeurs
   - Ils recevront une invitation

## 🔧 Configuration requise

### Pour Android :
- ✅ Flutter SDK installé
- ✅ Android SDK installé
- ✅ Java JDK installé

### Pour iOS :
- ✅ Mac avec macOS
- ✅ Xcode installé (dernière version recommandée)
- ✅ Compte développeur Apple
- ✅ Certificat de signature configuré

## 📦 Structure des fichiers générés

```
kcl_app/
├── build/
│   ├── app/
│   │   └── outputs/
│   │       └── flutter-apk/
│   │           ├── app-debug.apk
│   │           └── app-release.apk
│   └── ios/
│       └── iphoneos/
│           └── Runner.app
└── releases/
    ├── kcl_app_debug.apk
    ├── kcl_app_release.apk
    └── kcl_app.ipa (si généré)
```

## 🐛 Dépannage

### Android

**Erreur : "Gradle build failed"**
- Vérifiez que Java JDK est installé
- Exécutez `flutter doctor` pour diagnostiquer

**APK trop volumineux**
- Utilisez `flutter build apk --split-per-abi`
- Activez la compression ProGuard dans `android/app/build.gradle.kts`

### iOS

**Erreur : "No signing certificate found"**
- Ouvrez le projet dans Xcode
- Configurez votre Team dans Signing & Capabilities

**Erreur : "Provisioning profile not found"**
- Créez un profil de provisionnement dans le portail développeur Apple
- Ou laissez Xcode le créer automatiquement

**IPA ne s'installe pas**
- Vérifiez que l'UDID de l'appareil est dans le profil de provisionnement
- Utilisez TestFlight pour une installation plus simple

## 📝 Notes importantes

1. **Version de l'application** : Modifiez `version` dans `pubspec.yaml` avant chaque build
2. **Clés API** : Vérifiez que `lib/config/supabase_config.dart` contient les bonnes clés
3. **Permissions** : Vérifiez les permissions dans `AndroidManifest.xml` et `Info.plist`
4. **Icônes** : Générez les icônes avec `flutter pub run flutter_launcher_icons`

## 🔐 Sécurité

- ⚠️ Ne partagez jamais vos clés API Supabase publiquement
- ⚠️ Le fichier `lib/config/supabase_config.dart` est dans `.gitignore`
- ⚠️ Utilisez des variables d'environnement pour la production

## 📞 Support

Pour toute question ou problème, consultez :
- [Documentation Flutter](https://flutter.dev/docs)
- [Guide de déploiement Flutter](https://flutter.dev/docs/deployment)

