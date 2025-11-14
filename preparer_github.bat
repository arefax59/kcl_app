@echo off
chcp 65001 >nul
echo ========================================
echo   PRÉPARATION POUR GITHUB
echo ========================================
echo.

echo Ce script va vous aider à pousser votre code sur GitHub
echo pour générer l'IPA iOS automatiquement.
echo.

REM Vérifier si Git est installé
git --version >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Git n'est pas installé !
    echo.
    echo Téléchargez Git depuis : https://git-scm.com/download/win
    echo.
    pause
    exit /b 1
)

echo [OK] Git est installé
echo.

REM Vérifier si c'est déjà un dépôt Git
if exist .git (
    echo [INFO] Dépôt Git déjà initialisé
    git status
    echo.
) else (
    echo [1/4] Initialisation du dépôt Git...
    git init
    echo.
)

echo [2/4] Ajout des fichiers...
git add .
echo.

echo [3/4] Création du commit...
git commit -m "Initial commit - KCL App" 2>nul
if errorlevel 1 (
    echo [INFO] Aucun changement à commiter ou commit déjà créé
) else (
    echo [OK] Commit créé
)
echo.

echo [4/4] Configuration du remote...
echo.
echo IMPORTANT : Vous devez créer un dépôt sur GitHub d'abord !
echo.
set /p github_url="Entrez l'URL de votre dépôt GitHub (ex: https://github.com/VOTRE_USERNAME/kcl-app.git): "

if "%github_url%"=="" (
    echo [ERREUR] URL vide !
    pause
    exit /b 1
)

REM Vérifier si le remote existe déjà
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    git remote add origin "%github_url%"
    echo [OK] Remote ajouté
) else (
    set /p replace="Remote existe déjà. Remplacer ? (o/n): "
    if /i "%replace%"=="o" (
        git remote set-url origin "%github_url%"
        echo [OK] Remote mis à jour
    )
)
echo.

echo ========================================
echo   ÉTAPES SUIVANTES
echo ========================================
echo.
echo 1. Vérifiez que votre code est bien poussé :
echo    git push -u origin main
echo.
echo 2. Allez sur GitHub dans l'onglet "Actions"
echo.
echo 3. Lancez le workflow "Build iOS"
echo.
echo 4. Téléchargez l'IPA depuis les Artifacts
echo.
echo ========================================
echo.

set /p push_now="Voulez-vous pousser le code maintenant ? (o/n): "
if /i "%push_now%"=="o" (
    echo.
    echo Poussage du code sur GitHub...
    git branch -M main
    git push -u origin main
    echo.
    echo [OK] Code poussé !
    echo.
    echo Allez maintenant sur GitHub > Actions > Build iOS > Run workflow
) else (
    echo.
    echo Pour pousser plus tard, exécutez :
    echo   git push -u origin main
)

echo.
pause

