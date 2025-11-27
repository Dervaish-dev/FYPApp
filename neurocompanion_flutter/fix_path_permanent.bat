@echo off
echo Adding Flutter and Dart to PATH...

REM Add Flutter and Dart to user PATH
setx PATH "%PATH%;C:\Users\derva\Desktop\flutter_windows_3.35.7-stable\flutter\bin;C:\Users\derva\Desktop\flutter_windows_3.35.7-stable\flutter\bin\cache\dart-sdk\bin" /M

echo.
echo ✅ Flutter and Dart added to PATH permanently!
echo.
echo You need to restart your terminal/PowerShell for changes to take effect.
echo.
echo After restarting, you can run:
echo   flutter --version
echo   dart --version
echo   flutter run -d windows
echo   flutter run -d emulator-5554
echo.
pause
