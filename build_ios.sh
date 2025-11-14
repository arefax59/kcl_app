#!/bin/bash

echo "========================================"
echo "  GÉNÉRATION IPA KCL APP (iOS)"
echo "========================================"
echo ""

echo "[1/4] Nettoyage..."
flutter clean
echo ""

echo "[2/4] Récupération des dépendances..."
flutter pub get
echo ""

echo "[3/4] Génération de l'IPA..."
echo ""
echo "Choisissez le type de build:"
echo "  1. Debug (pour tester)"
echo "  2. Release (pour production)"
echo ""
read -p "Votre choix (1 ou 2): " choice

if [ "$choice" == "1" ]; then
    echo "Génération IPA Debug..."
    flutter build ios --debug --no-codesign
    BUILD_PATH="build/ios/iphoneos/Runner.app"
    IPA_NAME="kcl_app_debug.ipa"
elif [ "$choice" == "2" ]; then
    echo "Génération IPA Release..."
    flutter build ios --release --no-codesign
    BUILD_PATH="build/ios/iphoneos/Runner.app"
    IPA_NAME="kcl_app_release.ipa"
else
    echo "Choix invalide!"
    exit 1
fi

echo ""
echo "[4/4] Création du dossier releases..."
mkdir -p releases

# Créer l'IPA (nécessite xcodebuild)
if command -v xcodebuild &> /dev/null; then
    echo "Création de l'IPA..."
    xcodebuild -exportArchive \
        -archivePath build/ios/archive/Runner.xcarchive \
        -exportPath releases \
        -exportOptionsPlist ios/ExportOptions.plist || {
        echo "⚠️  Note: Pour créer un IPA signé, vous devez:"
        echo "   1. Ouvrir ios/Runner.xcworkspace dans Xcode"
        echo "   2. Configurer votre certificat de signature"
        echo "   3. Archiver et exporter depuis Xcode"
    }
else
    echo "⚠️  xcodebuild non trouvé. Utilisez Xcode pour créer l'IPA."
fi

echo ""
echo "========================================"
echo "  BUILD iOS TERMINÉ!"
echo "========================================"
echo ""
echo "Pour créer un IPA signé:"
echo "  1. Ouvrez ios/Runner.xcworkspace dans Xcode"
echo "  2. Sélectionnez 'Any iOS Device' comme destination"
echo "  3. Menu Product > Archive"
echo "  4. Dans l'organisateur, cliquez sur 'Distribute App'"
echo "  5. Choisissez 'Ad Hoc' ou 'App Store'"
echo ""

