# 📱 Guide de Déploiement sur Téléphone

## 🚀 Méthode 1 : Installation Directe (Recommandée pour tester)

### Prérequis
- ✅ Téléphone Android connecté en USB
- ✅ Mode développeur activé sur le téléphone
- ✅ Débogage USB activé

### Étapes

#### 1. Activer le Mode Développeur sur votre téléphone
1. Allez dans **Paramètres** → **À propos du téléphone**
2. Appuyez 7 fois sur **Numéro de build**
3. Retournez dans **Paramètres** → **Options développeur**
4. Activez **Débogage USB**

#### 2. Connecter le téléphone et installer
```bash
# Vérifier que le téléphone est détecté
flutter devices

# Installer directement sur le téléphone
flutter run
```

L'app sera installée et lancée automatiquement sur votre téléphone !

---

## 📦 Méthode 2 : Générer un APK (Pour partager)

### Générer un APK Debug (pour tester)
```bash
flutter build apk --debug
```

L'APK sera généré dans : `build/app/outputs/flutter-apk/app-debug.apk`

### Générer un APK Release (pour production)
```bash
flutter build apk --release
```

L'APK sera généré dans : `build/app/outputs/flutter-apk/app-release.apk`

### Installer l'APK sur le téléphone
1. Copiez le fichier APK sur votre téléphone (USB, email, cloud)
2. Sur le téléphone, allez dans **Paramètres** → **Sécurité**
3. Activez **Sources inconnues** (autoriser l'installation d'apps)
4. Ouvrez le fichier APK et installez

---

## 🛠️ Commandes Utiles

### Vérifier la configuration
```bash
flutter doctor
flutter devices
```

### Nettoyer et reconstruire
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Voir les logs en temps réel
```bash
flutter run --verbose
```

---

## 📋 Checklist de Déploiement

- [ ] Mode développeur activé sur téléphone
- [ ] Débogage USB activé
- [ ] Téléphone connecté et détecté (`flutter devices`)
- [ ] Base de données configurée (à implémenter)
- [ ] APK généré ou installation directe réussie

---

## 🐛 Résolution de Problèmes

### Le téléphone n'est pas détecté
```bash
# Vérifier les pilotes USB
adb devices

# Redémarrer ADB
adb kill-server
adb start-server
```

### L'app crash au démarrage
- Vérifiez les logs : `flutter run --verbose`
- Vérifiez la connexion internet
- Vérifiez que la base de données est correctement configurée

---

## 📱 Pour iOS (si vous avez un iPhone)

1. Installez Xcode
2. Configurez un compte développeur Apple
3. Utilisez : `flutter build ios`
4. Ouvrez dans Xcode et déployez

---

## 🎯 Prochaines Étapes

Une fois l'app installée :
1. Testez la connexion
2. Configurez la base de données
3. Créez un compte admin
4. Testez l'envoi de notifications
5. Vérifiez la synchronisation entre appareils

Bon déploiement ! 🚀

