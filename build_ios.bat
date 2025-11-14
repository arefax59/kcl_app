@echo off
chcp 65001 >nul
echo ========================================
echo   COMPILATION iOS - GITHUB ACTIONS
echo ========================================
echo.
echo ⚠️  IMPORTANT : iOS nécessite un Mac avec Xcode
echo    Nous allons utiliser GitHub Actions pour compiler sur un Mac virtuel
echo.

REM Vérifier si Git est installé
git --version >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Git n'est pas installé !
    echo Téléchargez Git depuis : https://git-scm.com/download/win
    pause
    exit /b 1
)

echo [1/4] Vérification du dépôt Git...
if not exist .git (
    echo [ERREUR] Ce n'est pas un dépôt Git !
    echo.
    echo Initialisation du dépôt Git...
    git init
    git add .
    git commit -m "Initial commit - KCL App iOS"
    echo.
    echo Vous devez créer un dépôt sur GitHub et ajouter le remote :
    echo   git remote add origin https://github.com/VOTRE_USERNAME/kcl-app.git
    echo   git push -u origin main
    echo.
    pause
    exit /b 1
)

echo [OK] Dépôt Git trouvé
echo.

REM Vérifier le remote
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Aucun remote GitHub configuré !
    echo.
    set /p github_url="Entrez l'URL de votre dépôt GitHub: "
    if "%github_url%"=="" (
        echo [ERREUR] URL vide !
        pause
        exit /b 1
    )
    git remote add origin "%github_url%"
    echo [OK] Remote ajouté
    echo.
)

git remote get-url origin
echo.

echo [2/4] Vérification des fichiers nécessaires...
if not exist ".github\workflows\build_ios.yml" (
    echo [ERREUR] Fichier .github/workflows/build_ios.yml manquant !
    echo Le workflow GitHub Actions n'est pas configuré.
    pause
    exit /b 1
)
echo [OK] Workflow GitHub Actions trouvé
echo.

echo [3/4] Vérification des changements...
git status --short
echo.

set /p commit_changes="Y a-t-il des changements non commités ? (o/n): "
if /i "%commit_changes%"=="o" (
    echo.
    echo Ajout des changements...
    git add .
    git commit -m "Update for iOS build"
    echo [OK] Changements commités
    echo.
)

echo [4/4] Poussage sur GitHub...
git push origin main
if errorlevel 1 (
    echo.
    echo [ERREUR] Échec du push sur GitHub !
    echo.
    echo Vérifiez :
    echo   1. Que votre dépôt GitHub existe
    echo   2. Que vous avez les droits d'écriture
    echo   3. Que vous êtes authentifié (token GitHub)
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   CODE POUSSÉ SUR GITHUB
echo ========================================
echo.
echo Maintenant, lancez le build iOS :
echo.
echo 1. Allez sur votre dépôt GitHub
echo 2. Cliquez sur l'onglet "Actions"
echo 3. Sélectionnez "Build iOS" dans le menu de gauche
echo 4. Cliquez sur "Run workflow"
echo 5. Choisissez "release" ou "debug"
echo 6. Cliquez sur "Run workflow"
echo.
echo Le build prendra 5-10 minutes.
echo Une fois terminé, téléchargez l'IPA depuis les Artifacts.
echo.

REM Essayer d'ouvrir GitHub dans le navigateur
for /f "tokens=*" %%i in ('git remote get-url origin') do set GITHUB_URL=%%i
set GITHUB_URL=%GITHUB_URL:git@github.com:=https://github.com/%
set GITHUB_URL=%GITHUB_URL:.git=/actions%
set GITHUB_URL=%GITHUB_URL:https://github.com//=https://github.com/%

echo Voulez-vous ouvrir GitHub Actions dans votre navigateur ?
set /p open_browser="(o/n): "
if /i "%open_browser%"=="o" (
    start "" "%GITHUB_URL%"
)

echo.
pause

