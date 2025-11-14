@echo off
chcp 65001 >nul
echo ========================================
echo   DIAGNOSTIC DE COMPILATION
echo ========================================
echo.

echo [1/5] Vérification de Flutter...
flutter --version
if errorlevel 1 (
    echo [ERREUR] Flutter n'est pas installé ou pas dans le PATH
    pause
    exit /b 1
)
echo.

echo [2/5] Vérification de l'environnement...
flutter doctor
echo.

echo [3/5] Nettoyage du projet...
flutter clean
echo.

echo [4/5] Récupération des dépendances...
flutter pub get
if errorlevel 1 (
    echo [ERREUR] Échec de la récupération des dépendances
    pause
    exit /b 1
)
echo.

echo [5/5] Vérification de la configuration...
echo.
echo Vérification des fichiers de configuration...

if not exist "lib\config\supabase_config.dart" (
    echo [ERREUR] Fichier supabase_config.dart manquant !
    echo Créez-le avec vos clés Supabase
) else (
    echo [OK] supabase_config.dart existe
)

if not exist "android\app\build.gradle.kts" (
    echo [ERREUR] Fichier build.gradle.kts manquant !
) else (
    echo [OK] build.gradle.kts existe
)

echo.
echo ========================================
echo   TEST DE COMPILATION
echo ========================================
echo.
set /p test_build="Voulez-vous tester la compilation ? (o/n): "
if /i "%test_build%"=="o" (
    echo.
    echo Compilation en cours (peut prendre 2-3 minutes)...
    flutter build apk --debug
    if errorlevel 1 (
        echo.
        echo [ERREUR] La compilation a échoué !
        echo.
        echo Vérifiez les erreurs ci-dessus.
        echo.
        echo Solutions possibles :
        echo   1. Vérifiez que toutes les dépendances sont installées
        echo   2. Exécutez : flutter clean puis flutter pub get
        echo   3. Vérifiez que lib/config/supabase_config.dart existe
        echo   4. Vérifiez les logs d'erreur ci-dessus
    ) else (
        echo.
        echo [SUCCÈS] Compilation réussie !
        echo.
        echo APK généré dans : build\app\outputs\flutter-apk\app-debug.apk
    )
)

echo.
pause

