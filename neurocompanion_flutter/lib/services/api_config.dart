/// Configure via: flutter run --dart-define=API_BASE_URL=http://16.171.134.228:5005/api
///
/// Notes:
/// - AWS EC2 backend: http://16.171.134.228:5005/api
/// - Local backend: http://localhost:5005/api
/// - Android emulator to local: http://10.0.2.2:5005/api
/// - iOS simulator to local: http://localhost:5005/api
/// - Physical device on same network: http://192.168.x.x:5005/api
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://16.171.134.228:5005/api',
  );
}
