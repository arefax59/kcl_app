# 🚀 Déploiement Rapide - KCL App

## 📱 Android (APK)

### Étape 1 : Générer l'APK
```bash
# Windows
build_apk.bat

# Ou manuellement
flutter clean
flutter pub get
flutter build apk --release
```

### Étape 2 : Trouver l'APK
L'APK sera dans :
- `build/app/outputs/flutter-apk/app-release.apk`
- `releases/kcl_app_release.apk` (copie automatique)

### Étape 3 : Installer sur Android
1. Copiez `releases/kcl_app_release.apk` sur votre téléphone
2. Activez "Sources inconnues" dans Paramètres > Sécurité
3. Ouvrez l'APK et installez

---

## 🍎 iOS (IPA)

### ⚠️ Prérequis
- **Mac** avec macOS
- **Xcode** installé
- **Compte développeur Apple**

### Étape 1 : Ouvrir dans Xcode
```bash
open ios/Runner.xcworkspace
```

### Étape 2 : Configurer la signature
1. Sélectionnez le projet **Runner**
2. Onglet **Signing & Capabilities**
3. Sélectionnez votre **Team**

### Étape 3 : Archiver
1. Menu **Product** > **Archive**
2. Dans l'organisateur : **Distribute App**
3. Choisissez **Ad Hoc** ou **App Store Connect**

### Étape 4 : Installer
- **Ad Hoc** : Glissez l'IPA dans Finder (iPhone connecté)
- **TestFlight** : Téléversez sur App Store Connect

---

## 📦 Fichiers générés

```
releases/
├── kcl_app_debug.apk      (Android - Debug)
├── kcl_app_release.apk    (Android - Release)
└── kcl_app.ipa            (iOS - si généré)
```

---

## 🔧 Dépannage rapide

### Android
- **Erreur Gradle** : `flutter doctor` puis `flutter clean`
- **APK trop gros** : `flutter build apk --split-per-abi`

### iOS
- **Pas de certificat** : Configurez votre Team dans Xcode
- **IPA ne s'installe pas** : Vérifiez l'UDID dans le profil de provisionnement

---

📖 **Guide complet** : Voir `GUIDE_DEPLOIEMENT_APK_IOS.md`

