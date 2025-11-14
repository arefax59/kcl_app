@echo off
echo ========================================
echo   DEPLOIEMENT KCL APP SUR TELEPHONE
echo ========================================
echo.

echo [1/4] Verification de Flutter...
flutter doctor
echo.

echo [2/4] Verification des appareils connectes...
flutter devices
echo.

echo [3/4] Nettoyage et recuperation des dependances...
flutter clean
flutter pub get
echo.

echo [4/4] Installation sur le telephone...
echo.
echo ATTENTION: Assurez-vous que:
echo   - Votre telephone est connecte en USB
echo   - Le mode developpeur est active
echo   - Le debogage USB est active
echo.
pause

flutter run

echo.
echo ========================================
echo   Installation terminee!
echo ========================================
pause

