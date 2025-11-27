# Add Flutter and Dart to PATH for current session
$flutterPath = "C:\Users\derva\Desktop\flutter_windows_3.35.7-stable\flutter\bin"
$dartPath = "C:\Users\derva\Desktop\flutter_windows_3.35.7-stable\flutter\bin\cache\dart-sdk\bin"

# Add to current session PATH
$env:PATH += ";$flutterPath;$dartPath"

Write-Host "✅ Flutter and Dart added to PATH for this session"
Write-Host "Flutter path: $flutterPath"
Write-Host "Dart path: $dartPath"
Write-Host ""

# Test Flutter
Write-Host "Testing Flutter..."
flutter --version

Write-Host ""
Write-Host "Testing Dart..."
dart --version

Write-Host ""
Write-Host "🚀 Now you can run Flutter commands!"
Write-Host "Try: flutter run -d windows"
Write-Host "Or: flutter run -d emulator-5554"
