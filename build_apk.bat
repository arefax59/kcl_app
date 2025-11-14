@echo off
chcp 65001 >nul
echo ========================================
echo   GÉNÉRATION APK KCL APP
echo ========================================
echo.

echo [1/4] Nettoyage...
flutter clean
echo.

echo [2/4] Récupération des dépendances...
flutter pub get
echo.

echo [3/4] Génération de l'APK...
echo.
echo Choisissez le type d'APK:
echo   1. Debug (pour tester)
echo   2. Release (pour production)
echo.
set /p choice="Votre choix (1 ou 2): "

set APK_PATH=
set APK_NAME=

if "%choice%"=="1" (
    echo Génération APK Debug...
    flutter build apk --debug
    set APK_PATH=build\app\outputs\flutter-apk\app-debug.apk
    set APK_NAME=kcl_app_debug.apk
) else if "%choice%"=="2" (
    echo Génération APK Release...
    flutter build apk --release
    set APK_PATH=build\app\outputs\flutter-apk\app-release.apk
    set APK_NAME=kcl_app_release.apk
) else (
    echo Choix invalide!
    pause
    exit /b 1
)

echo.
echo [4/4] Copie de l'APK dans le dossier releases...
if not exist "releases" mkdir releases
copy "%APK_PATH%" "releases\%APK_NAME%"
echo.

echo ========================================
echo   APK GÉNÉRÉ AVEC SUCCÈS!
echo ========================================
echo.
echo Fichier APK disponible dans:
echo   - %APK_PATH%
echo   - releases\%APK_NAME%
echo.
echo Pour installer sur votre téléphone Android:
echo   1. Copiez l'APK (releases\%APK_NAME%) sur votre téléphone
echo   2. Activez "Sources inconnues" dans les paramètres
echo   3. Ouvrez le fichier APK et installez
echo.
echo Pour transférer l'APK sur votre PC:
echo   - Le fichier est dans le dossier "releases" de ce projet
echo.
pause

