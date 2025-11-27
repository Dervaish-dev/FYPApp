@echo off
cd /d "%~dp0"
echo Starting NeuroCompanion Flutter App...
echo.
echo Available options:
echo 1. Run on Chrome (recommended)
echo 2. Run on Windows Desktop
echo 3. Run on Android (if connected)
echo.
set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" (
    echo Starting on Chrome...
    flutter run -d chrome
) else if "%choice%"=="2" (
    echo Starting on Windows Desktop...
    flutter run -d windows
) else if "%choice%"=="3" (
    echo Starting on Android...
    flutter run -d android
) else (
    echo Invalid choice. Starting on Chrome by default...
    flutter run -d chrome
)

pause