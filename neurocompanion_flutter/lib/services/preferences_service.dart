import 'package:neurocompanion_flutter/services/api_client.dart';

class UserPreferences {
  final String userId;
  final String defaultTheme; // backend: ocean/coral/dark/mint/lavender
  final bool adaptiveMode;
  final bool notificationsEnabled;
  final String language;

  const UserPreferences({
    required this.userId,
    required this.defaultTheme,
    required this.adaptiveMode,
    required this.notificationsEnabled,
    required this.language,
  });

  static UserPreferences fromJson(Object? json) {
    if (json is! Map) {
      return const UserPreferences(
        userId: '',
        defaultTheme: 'ocean',
        adaptiveMode: false,
        notificationsEnabled: true,
        language: 'english',
      );
    }

    return UserPreferences(
      userId: (json['userId'] ?? '').toString(),
      defaultTheme: (json['defaultTheme'] ?? 'ocean').toString(),
      adaptiveMode: json['adaptiveMode'] == true,
      notificationsEnabled: json['notificationsEnabled'] != false,
      language: (json['language'] ?? 'english').toString(),
    );
  }
}

class PreferencesService {
  final ApiClient _api;

  PreferencesService({required ApiClient apiClient}) : _api = apiClient;

  Future<UserPreferences> fetch(String userId) async {
    final json = await _api.get('/preferences/$userId', authenticated: true);
    if (json is Map && json['data'] != null) {
      return UserPreferences.fromJson(json['data']);
    }
    return UserPreferences.fromJson(null);
  }

  /// Creates or updates preferences.
  Future<UserPreferences> upsert({
    required String userId,
    String? defaultTheme,
    bool? adaptiveMode,
    bool? notificationsEnabled,
    String? language,
  }) async {
    final payload = <String, Object?>{
      'userId': userId,
      if (defaultTheme != null) 'defaultTheme': defaultTheme,
      if (adaptiveMode != null) 'adaptiveMode': adaptiveMode,
      if (notificationsEnabled != null)
        'notificationsEnabled': notificationsEnabled,
      if (language != null) 'language': language,
    };

    final json = await _api.post('/preferences', authenticated: true, body: payload);
    if (json is Map && json['data'] != null) {
      return UserPreferences.fromJson(json['data']);
    }

    // Some routes may return { success, data: preferences } already handled;
    // fallback to refetch if response shape changes.
    return fetch(userId);
  }
}
