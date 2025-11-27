// API Configuration
// This file should NOT contain real API keys
// 
// To use your API key:
// 1. Copy lib/config/api_keys.dart.example to lib/config/api_keys.dart
// 2. Add your actual API key in api_keys.dart
// 3. The api_keys.dart file is gitignored and won't be committed

// Import the API key from api_keys.dart (users must create this file)
// If api_keys.dart doesn't exist, this will use the stub file
import 'api_keys_stub.dart' as keys;

class ApiConfig {
  // Get API key from local config file (not in git)
  // Users must create lib/config/api_keys.dart for this to work
  static String get geminiApiKey => keys.geminiApiKey;
  
  static bool get isApiKeyConfigured {
    final key = geminiApiKey;
    return key.isNotEmpty && key != 'your_gemini_api_key_here';
  }
}

