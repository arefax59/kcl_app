# KCL App

Application mobile multi-plateforme pour la gestion des horaires et l'optimisation d'itinéraires pour KCL.

## Fonctionnalités

### Gestion des horaires
- Saisie et suivi des horaires de travail par jour
- Calcul automatique du total d'heures par mois
- Export par email avec tableau formaté (HTML et texte)
- Tableau avec bordures pour une meilleure lisibilité

### Optimisation d'itinéraires
- Carte interactive avec géolocalisation
- Ajout de points d'arrêt (jusqu'à 90)
- Options d'horaires :
  - Horaires prédéfinis (9h, 10h, 13h, 18h)
  - Heures d'ouverture/fermeture personnalisées
  - Rendez-vous avec plages horaires (format: 10h00-12h00)
- Recherche d'adresses complètes avec géocodage
- Optimisation automatique de l'itinéraire
- Tracé suivant les routes réelles via OSRM
- Sauvegarde automatique des points d'arrêt

### Messagerie
- Communication entre administrateurs et utilisateurs
- Notifications en temps réel

## Technologies

- **Framework**: Flutter 3.0+
- **Backend**: Supabase
- **Cartes**: flutter_map avec OpenStreetMap
- **Géolocalisation**: geolocator
- **Géocodage**: geocoding
- **Routage**: OSRM (Open Source Routing Machine)

## Configuration

### Prérequis

- Flutter SDK >= 3.0.0
- Android Studio / Xcode
- Compte Supabase

### Installation

1. Cloner le repository
```bash
git clone https://github.com/arefax59/kcl_app.git
cd kcl_app
```

2. Installer les dépendances
```bash
flutter pub get
```

3. Configurer Supabase
   - Créer le fichier `lib/config/supabase_config.dart` avec vos clés Supabase
   - Voir la documentation Supabase pour la structure des tables

4. Générer les icônes et splash screen
```bash
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

## Build

### Android
```bash
flutter build apk --release
# ou
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Codemagic

Le projet est configuré pour être buildé automatiquement sur Codemagic. Le fichier `codemagic.yaml` contient les workflows pour Android et iOS.

### Configuration requise sur Codemagic

1. **Android**:
   - Créer un groupe "keystore_credentials" avec les certificats de signature
   - Variables d'environnement : `APP_ID`, `PACKAGE_NAME`

2. **iOS**:
   - Créer un groupe "app_store_credentials" avec les certificats Apple
   - Variables d'environnement : `APP_ID`, `BUNDLE_ID`

## Structure du projet

```
lib/
├── config/
│   └── supabase_config.dart      # Configuration Supabase (non versionné)
├── screens/
│   ├── admin_screen.dart         # Écran administrateur
│   ├── home_screen.dart          # Écran principal
│   ├── dpd_screen.dart           # Écran DPD
│   ├── chronopost_screen.dart    # Écran Chronopost
│   ├── login_screen.dart         # Écran de connexion
│   ├── map_screen.dart           # Écran Optim (carte)
│   └── splash_screen.dart        # Écran de démarrage
└── services/
    ├── notification_service.dart # Service de notifications
    └── supabase_service.dart     # Service Supabase
```

## Permissions

### Android
- `ACCESS_FINE_LOCATION` : Pour la géolocalisation
- `ACCESS_COARSE_LOCATION` : Pour la géolocalisation approximative

### iOS
- `NSLocationWhenInUseUsageDescription` : Pour la géolocalisation
- `NSLocationAlwaysUsageDescription` : Pour la géolocalisation en arrière-plan

## Version

1.0.0+1

## Auteur

Johann Trachez

## Licence

Propriétaire - Tous droits réservés

