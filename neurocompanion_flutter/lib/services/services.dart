import 'package:neurocompanion_flutter/models/models.dart';
import 'package:neurocompanion_flutter/models/task.dart';
import 'package:neurocompanion_flutter/services/api_client.dart';
import 'package:neurocompanion_flutter/services/api_config.dart';
import 'package:neurocompanion_flutter/services/api_exceptions.dart';
import 'package:neurocompanion_flutter/services/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

// Authentication Service
class AuthService {
  static const String _userKey = 'current_user';

  final TokenStore _tokenStore;
  final ApiClient _api;
  User? _cachedUser;

  AuthService({TokenStore? tokenStore, ApiClient? apiClient})
      : _tokenStore = tokenStore ?? SharedPrefsTokenStore(),
        _api = apiClient ?? ApiClient(baseUrl: ApiConfig.baseUrl, tokenStore: tokenStore ?? SharedPrefsTokenStore());

  User? get currentUser => _cachedUser;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final json = await _api.post(
      '/auth/login',
      authenticated: false,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected login response');
    }

    // Check if 2FA is required
    if (json['requires2FA'] == true) {
      return {
        'requires2FA': true,
        'userId': json['userId'] ?? '',
      };
    }

    final data = json['data'];
    if (data is! Map) {
      throw ApiException(message: (json['message'] ?? 'Login failed').toString());
    }

    final token = (data['token'] ?? '').toString();
    final userMap = data['user'];
    if (token.isEmpty || userMap is! Map) {
      throw const ApiException(message: 'Login response missing token/user');
    }

    await _tokenStore.writeToken(token);

    final user = User(
      id: (userMap['id'] ?? '').toString(),
      name: (userMap['name'] ?? '').toString(),
      email: (userMap['email'] ?? '').toString(),
      createdAt: DateTime.now(),
    );

    _cachedUser = user;
    await _saveUser(user);
    
    return {
      'requires2FA': false,
      'user': user,
    };
  }

  Future<User> register(String name, String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // Mock registration
    if (name.isNotEmpty && email.isNotEmpty && password.length >= 6) {
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );

      await _saveUser(user);
      return user;
    } else {
      throw Exception('Registration failed');
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', authenticated: true, body: {});
    } catch (_) {
      // ignore network errors on logout; client-side clear is sufficient
    }

    _cachedUser = null;
    final prefs = await SharedPreferences.getInstance();
    
    // Save theme preferences before clearing
    final savedTheme = prefs.getString('neurocompanion-theme');
    final savedFontSize = prefs.getDouble('neurocompanion-fontSize');
    final savedAdaptiveMode = prefs.getBool('neurocompanion-adaptiveMode');
    
    // Clear all data
    await prefs.clear();
    
    // Restore theme preferences
    if (savedTheme != null) await prefs.setString('neurocompanion-theme', savedTheme);
    if (savedFontSize != null) await prefs.setDouble('neurocompanion-fontSize', savedFontSize);
    if (savedAdaptiveMode != null) await prefs.setBool('neurocompanion-adaptiveMode', savedAdaptiveMode);
    
    await _tokenStore.clearToken();
  }

  Future<User?> getCurrentUser() async {
    if (_cachedUser != null) return _cachedUser;
    
    final token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    // Try to get from local storage first (faster)
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        final userMap = json.decode(userJson);
        final user = User(
          id: userMap['id'],
          name: userMap['name'],
          email: userMap['email'],
          createdAt: DateTime.parse(userMap['createdAt']),
        );
        _cachedUser = user;
        return user;
      } catch (e) {
        print('Error parsing cached user: $e');
      }
    }

    // Fallback: try to fetch from backend
    try {
      // Try patient endpoint first
      try {
        final json = await _api.get('/auth/me', authenticated: true);
        if (json is Map && json['data'] is Map && (json['data'] as Map)['user'] is Map) {
          final userMap = (json['data'] as Map)['user'] as Map;
          final user = User(
            id: (userMap['id'] ?? '').toString(),
            name: (userMap['name'] ?? '').toString(),
            email: (userMap['email'] ?? '').toString(),
            createdAt: DateTime.now(),
            role: 'patient',
          );
          _cachedUser = user;
          await _saveUser(user);
          return user;
        }
      } catch (_) {
        // If patient endpoint fails, try caregiver endpoint
        final json = await _api.get('/caregiver/me', authenticated: true);
        if (json is Map && json['caregiver'] is Map) {
          final caregiverMap = json['caregiver'] as Map;
          final user = User(
            id: (caregiverMap['id'] ?? '').toString(),
            name: (caregiverMap['name'] ?? '').toString(),
            email: (caregiverMap['email'] ?? '').toString(),
            createdAt: DateTime.now(),
            role: 'caregiver',
          );
          _cachedUser = user;
          await _saveUser(user);
          return user;
        }
      }
    } catch (e) {
      print('Error fetching user from backend: $e');
    }
    
    return null;
  }

  /// Completes invite-only signup. Backend returns { data: { user, token } }.
  Future<User> finalizeInviteSignup({required String claimToken, required String password}) async {
    final json = await _api.post(
      '/invites/claim/finalize',
      authenticated: false,
      body: {
        'claimToken': claimToken.trim(),
        'password': password,
      },
    );

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected signup response');
    }

    final data = json['data'];
    if (data is! Map) {
      throw ApiException(message: (json['message'] ?? 'Signup failed').toString());
    }

    final token = (data['token'] ?? '').toString();
    final userMap = data['user'];
    if (token.isEmpty || userMap is! Map) {
      throw const ApiException(message: 'Signup response missing token/user');
    }

    await _tokenStore.writeToken(token);

    final user = User(
      id: (userMap['id'] ?? '').toString(),
      name: (userMap['name'] ?? '').toString(),
      email: (userMap['email'] ?? '').toString(),
      createdAt: DateTime.now(),
    );

    await _saveUser(user);
    return user;
  }

  Future<User> verify2FA(String userId, String otp) async {
    final json = await _api.post(
      '/auth/verify-2fa',
      authenticated: false,
      body: {
        'userId': userId,
        'otp': otp,
      },
    );

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected 2FA response');
    }

    final data = json['data'];
    if (data is! Map) {
      throw ApiException(message: (json['message'] ?? '2FA verification failed').toString());
    }

    final token = (data['token'] ?? '').toString();
    final userMap = data['user'];
    if (token.isEmpty || userMap is! Map) {
      throw const ApiException(message: '2FA response missing token/user');
    }

    await _tokenStore.writeToken(token);

    final user = User(
      id: (userMap['id'] ?? '').toString(),
      name: (userMap['name'] ?? '').toString(),
      email: (userMap['email'] ?? '').toString(),
      createdAt: DateTime.now(),
    );

    _cachedUser = user;
    await _saveUser(user);
    return user;
  }

  Future<Map<String, dynamic>> toggle2FA() async {
    final json = await _api.post('/auth/toggle-2fa', authenticated: true, body: {});
    
    if (json is! Map) {
      throw const ApiException(message: 'Unexpected toggle 2FA response');
    }

    return {
      'twoFactorEnabled': json['twoFactorEnabled'] ?? false,
      'message': json['message'] ?? '2FA updated',
    };
  }

  Future<void> forgotPassword(String email) async {
    final json = await _api.post(
      '/auth/forgot-password',
      authenticated: false,
      body: {'email': email.trim()},
    );

    if (json is! Map || json['success'] != true) {
      throw ApiException(
        message: (json is Map ? json['message'] : 'Failed to send reset code') ?? 'Failed to send reset code',
      );
    }
  }

  Future<void> verifyResetOTP(String email, String otp) async {
    final json = await _api.post(
      '/auth/verify-reset-otp',
      authenticated: false,
      body: {
        'email': email.trim(),
        'otp': otp,
      },
    );

    if (json is! Map || json['success'] != true) {
      throw ApiException(
        message: (json is Map ? json['message'] : 'Invalid OTP') ?? 'Invalid OTP',
      );
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    final json = await _api.post(
      '/auth/reset-password',
      authenticated: false,
      body: {
        'email': email.trim(),
        'otp': otp,
        'newPassword': newPassword,
      },
    );

    if (json is! Map || json['success'] != true) {
      throw ApiException(
        message: (json is Map ? json['message'] : 'Failed to reset password') ?? 'Failed to reset password',
      );
    }
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'createdAt': user.createdAt.toIso8601String(),
    });
    await prefs.setString(_userKey, userJson);
  }
}

// Task Service
class TaskService {
  static const String _userKey = 'current_user';

  final ApiClient _api;

  TaskService({ApiClient? apiClient, TokenStore? tokenStore})
      : _api = apiClient ??
            ApiClient(
              baseUrl: ApiConfig.baseUrl,
              tokenStore: tokenStore ?? SharedPrefsTokenStore(),
            );

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null || userJson.isEmpty) {
      throw const ApiException(message: 'Not logged in');
    }
    final map = json.decode(userJson);
    final id = (map is Map ? (map['id'] ?? '').toString() : '');
    if (id.isEmpty) {
      throw const ApiException(message: 'Missing user id');
    }
    return id;
  }

  String _toBackendStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in-progress';
      case TaskStatus.completed:
        return 'done';
    }
  }

  TaskStatus _fromBackendStatus(String status) {
    switch (status) {
      case 'in-progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.completed;
      case 'todo':
      default:
        return TaskStatus.todo;
    }
  }

  String _toBackendPriority(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
      case TaskPriority.urgent:
        return 'high';
    }
  }

  TaskPriority _fromBackendPriority(String priority) {
    switch (priority) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }

  Task _taskFromBackend(Map task) {
    final id = (task['_id'] ?? task['id'] ?? '').toString();
    final title = (task['title'] ?? '').toString();
    final description = (task['description'] ?? '').toString();

    final dueTimeRaw = task['dueTime'];
    final createdAtRaw = task['createdAt'];
    final completedAtRaw = task['completedAt'];

    final dueDate = dueTimeRaw != null ? DateTime.tryParse(dueTimeRaw.toString()) : null;
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw.toString()) ?? DateTime.now()
        : DateTime.now();
    final completedAt = completedAtRaw != null ? DateTime.tryParse(completedAtRaw.toString()) : null;

    return Task(
      id: id,
      title: title,
      description: description,
      priority: _fromBackendPriority((task['priority'] ?? 'medium').toString()),
      status: _fromBackendStatus((task['status'] ?? 'todo').toString()),
      dueDate: dueDate,
      reminderTime: null,
      createdAt: createdAt,
      completedAt: completedAt,
    );
  }

  Future<List<Task>> getTasks() async {
    final userId = await _getUserId();
    final json = await _api.get('/tasks/$userId', authenticated: true);

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected tasks response');
    }
    final data = json['data'];
    if (data is! Map) {
      throw ApiException(message: (json['message'] ?? 'Failed to fetch tasks').toString());
    }
    final tasksAny = data['tasks'];
    if (tasksAny is! List) return [];

    return tasksAny.whereType<Map>().map(_taskFromBackend).toList();
  }

  Future<void> addTask(Task task, {String repeat = 'once', List<String>? repeatDays}) async {
    final userId = await _getUserId();
    final dueTime = (task.dueDate ?? DateTime.now().add(const Duration(days: 1))).toIso8601String();

    final body = <String, dynamic>{
      'userId': userId,
      'title': task.title,
      'description': task.description,
      'priority': _toBackendPriority(task.priority),
      'dueTime': dueTime,
      'repeat': repeat,
    };

    if (repeatDays != null && repeatDays.isNotEmpty) {
      body['repeatDays'] = repeatDays;
    }

    await _api.post('/tasks/create', authenticated: true, body: body);
  }

  Future<void> updateTask(Task task) async {
    final update = <String, dynamic>{
      'title': task.title,
      'description': task.description,
      'priority': _toBackendPriority(task.priority),
      'status': _toBackendStatus(task.status),
    };

    if (task.dueDate != null) {
      update['dueTime'] = task.dueDate!.toIso8601String();
    }
    if (task.status == TaskStatus.completed) {
      update['completedAt'] = (task.completedAt ?? DateTime.now()).toIso8601String();
    }

    await _api.put('/tasks/${task.id}', authenticated: true, body: update);
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final update = <String, dynamic>{
      'status': _toBackendStatus(status),
    };
    if (status == TaskStatus.completed) {
      update['completedAt'] = DateTime.now().toIso8601String();
    }
    await _api.put('/tasks/$taskId', authenticated: true, body: update);
  }

  Future<void> deleteTask(String taskId) async {
    await _api.delete('/tasks/$taskId', authenticated: true);
  }
}

// Emotion Service
class EmotionService {
  static const String _userKey = 'current_user';

  final ApiClient _api;

  EmotionService({ApiClient? apiClient, TokenStore? tokenStore})
      : _api = apiClient ??
            ApiClient(
              baseUrl: ApiConfig.baseUrl,
              tokenStore: tokenStore ?? SharedPrefsTokenStore(),
            );

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null || userJson.isEmpty) {
      throw const ApiException(message: 'Not logged in');
    }
    final map = json.decode(userJson);
    final id = (map is Map ? (map['id'] ?? '').toString() : '');
    if (id.isEmpty) {
      throw const ApiException(message: 'Missing user id');
    }
    return id;
  }

  Emotion _emotionFromBackend(Map emotion) {
    final id = (emotion['_id'] ?? emotion['id'] ?? '').toString();
    final name = (emotion['emotion'] ?? '').toString();
    final intensity = int.tryParse((emotion['intensity'] ?? 5).toString()) ?? 5;
    final note = emotion['note']?.toString();
    final timestampRaw = emotion['timestamp'];
    final timestamp = timestampRaw != null
        ? DateTime.tryParse(timestampRaw.toString()) ?? DateTime.now()
        : DateTime.now();

    return Emotion(
      id: id,
      emotion: name,
      intensity: intensity,
      note: note,
      timestamp: timestamp,
    );
  }

  Future<List<Emotion>> getEmotions() async {
    final userId = await _getUserId();
    final json = await _api.get('/emotions/history/$userId', authenticated: true);

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected emotions response');
    }
    final data = json['data'];
    if (data is! Map) {
      throw ApiException(message: (json['message'] ?? 'Failed to fetch emotions').toString());
    }
    final emotionsAny = data['emotions'];
    if (emotionsAny is! List) return [];

    return emotionsAny.whereType<Map>().map(_emotionFromBackend).toList();
  }

  Future<void> addEmotion(String emotion, int intensity, String? note) async {
    final userId = await _getUserId();
    await _api.post(
      '/emotions/history',
      authenticated: true,
      body: {
        'userId': userId,
        'emotion': emotion.trim().toLowerCase(),
        'intensity': intensity,
        'confidence': 1.0,
        'note': note ?? '',
        'source': 'manual',
      },
    );
  }

  Future<void> deleteEmotion(String emotionId) async {
    await _api.delete('/emotions/history/$emotionId', authenticated: true);
  }

  /// Analyze emotion from image using backend Gemini AI
  Future<Map<String, dynamic>> analyzeEmotionFromImage(
    File imageFile, {
    String? userContext,
  }) async {
    final extraHeaders = <String, String>{};
    final trimmed = (userContext ?? '').trim();
    if (trimmed.isNotEmpty) {
      extraHeaders['X-User-Context'] = trimmed;
    }

    final res = await _api.postMultipart(
      '/emotion/analyze',
      fileField: 'image',
      file: imageFile,
      extraHeaders: extraHeaders.isEmpty ? null : extraHeaders,
      authenticated: true,
    );

    if (res is Map<String, dynamic>) return res;
    if (res is Map) return res.map((k, v) => MapEntry(k.toString(), v));
    throw const ApiException(message: 'Unexpected image analysis response');
  }

  /// Analyze facial emotion using Hugging Face model
  Future<Map<String, dynamic>> analyzeFacialEmotion(File imageFile) async {
    final res = await _api.postMultipart(
      '/emotion/analyze-face',
      fileField: 'image',
      file: imageFile,
      authenticated: true,
    );

    if (res is Map<String, dynamic>) return res;
    if (res is Map) return res.map((k, v) => MapEntry(k.toString(), v));
    throw const ApiException(message: 'Unexpected facial emotion analysis response');
  }
}

// Journal Service
class JournalService {
  static const String _userKey = 'current_user';

  final ApiClient _api;

  JournalService({ApiClient? apiClient, TokenStore? tokenStore})
      : _api = apiClient ??
            ApiClient(
              baseUrl: ApiConfig.baseUrl,
              tokenStore: tokenStore ?? SharedPrefsTokenStore(),
            );

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null || userJson.isEmpty) {
      throw const ApiException(message: 'Not logged in');
    }
    final map = json.decode(userJson);
    final id = (map is Map ? (map['id'] ?? '').toString() : '');
    if (id.isEmpty) {
      throw const ApiException(message: 'Missing user id');
    }
    return id;
  }

  JournalEntry _entryFromBackend(Map entry) {
    final id = (entry['_id'] ?? entry['id'] ?? '').toString();
    final content = (entry['content'] ?? '').toString();
    final emotion = entry['emotion']?.toString();
    final emotionConfidence = (entry['emotionConfidence'] ?? 0.0) is num
        ? (entry['emotionConfidence'] ?? 0.0).toDouble()
        : 0.0;
    final aiAnalysis = entry['aiAnalysis']?.toString();
    final createdAtRaw = entry['createdAt'];
    final updatedAtRaw = entry['updatedAt'];

    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw.toString()) ?? DateTime.now()
        : DateTime.now();
    final updatedAt = updatedAtRaw != null ? DateTime.tryParse(updatedAtRaw.toString()) : null;

    return JournalEntry(
      id: id,
      content: content,
      emotion: emotion,
      emotionConfidence: emotionConfidence,
      aiAnalysis: aiAnalysis,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Future<List<JournalEntry>> listByUser(String userId) async {
    final json = await _api.get('/journal/$userId', authenticated: true);

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected journal response');
    }

    final data = json['data'];
    if (data is! Map) {
      throw ApiException(message: (json['message'] ?? 'Failed to fetch journal entries').toString());
    }

    final entriesAny = data['entries'];
    if (entriesAny is! List) return [];

    return entriesAny.whereType<Map>().map(_entryFromBackend).toList();
  }

  Future<List<JournalEntry>> getJournalEntries() async {
    final userId = await _getUserId();
    return listByUser(userId);
  }

  Future<JournalEntry> create({
    required String userId,
    required String content,
    required int mood,
    required List<String> tags,
  }) async {
    final body = <String, dynamic>{
      'userId': userId,
      'content': content,
      'mood': mood,
      'tags': tags,
    };

    final json = await _api.post('/journal/create', authenticated: true, body: body);
    
    if (json is! Map) {
      throw const ApiException(message: 'Unexpected journal response');
    }

    final data = json['data'];
    if (data is! Map) {
      throw ApiException(message: (json['message'] ?? 'Failed to create journal entry').toString());
    }

    // Backend returns entry directly in 'data', not nested in 'data.entry'
    return _entryFromBackend(data);
  }

  Future<void> addJournalEntry(String content, String? emotion) async {
    final userId = await _getUserId();
    final body = <String, dynamic>{
      'userId': userId,
      'content': content,
    };
    if (emotion != null && emotion.trim().isNotEmpty) {
      body['emotion'] = emotion.trim().toLowerCase();
    }

    await _api.post('/journal/create', authenticated: true, body: body);
  }

  Future<JournalEntry> update(String entryId, String content) async {
    final json = await _api.put(
      '/journal/$entryId',
      authenticated: true,
      body: {
        'content': content,
      },
    );

    if (json is! Map) {
      throw const ApiException(message: 'Unexpected journal response');
    }

    final data = json['data'];
    if (data is! Map) {
      throw ApiException(message: (json['message'] ?? 'Failed to update journal entry').toString());
    }

    // Backend returns entry directly in 'data', not nested in 'data.entry'
    return _entryFromBackend(data);
  }

  Future<void> updateJournalEntry(String entryId, String content) async {
    await update(entryId, content);
  }

  Future<void> delete(String entryId) async {
    await _api.delete('/journal/$entryId', authenticated: true);
  }

  Future<void> deleteJournalEntry(String entryId) async {
    await delete(entryId);
  }
}

// Wellness Service
class WellnessService {
  static const String _userKey = 'current_user';

  final ApiClient _api;

  WellnessService({ApiClient? apiClient, TokenStore? tokenStore})
      : _api = apiClient ??
            ApiClient(
              baseUrl: ApiConfig.baseUrl,
              tokenStore: tokenStore ?? SharedPrefsTokenStore(),
            );

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null || userJson.isEmpty) {
      throw const ApiException(message: 'Not logged in');
    }
    final map = json.decode(userJson);
    final id = (map is Map ? (map['id'] ?? '').toString() : '');
    if (id.isEmpty) {
      throw const ApiException(message: 'Missing user id');
    }
    return id;
  }

  Future<Map<String, dynamic>> getAnalytics({int days = 30}) async {
    final userId = await _getUserId();
    final res = await _api.get('/wellness/analytics/$userId?days=$days', authenticated: true);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return res.map((k, v) => MapEntry(k.toString(), v));
    throw const ApiException(message: 'Unexpected wellness analytics response');
  }

  // Sleep
  Future<void> logSleep({
    required String bedtime,
    required String wakeTime,
    required double sleepDuration,
    int? sleepQuality,
  }) async {
    final userId = await _getUserId();
    await _api.post(
      '/wellness/sleep',
      authenticated: true,
      body: {
        'userId': userId,
        'bedtime': bedtime,
        'wakeTime': wakeTime,
        'sleepDuration': sleepDuration,
        if (sleepQuality != null) 'sleepQuality': sleepQuality,
      },
    );
  }

  Future<Map<String, dynamic>> getSleep({int days = 7}) async {
    final userId = await _getUserId();
    final res = await _api.get('/wellness/sleep/$userId?days=$days', authenticated: true);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return res.map((k, v) => MapEntry(k.toString(), v));
    throw const ApiException(message: 'Unexpected sleep response');
  }

  // Breathing
  Future<void> logBreathing({
    required double durationMinutes,
    required int cycles,
    int? stressLevel,
    String? beforeMood,
    String? afterMood,
  }) async {
    final userId = await _getUserId();
    await _api.post(
      '/wellness/breathing',
      authenticated: true,
      body: {
        'userId': userId,
        'duration': durationMinutes,
        'cycles': cycles,
        if (stressLevel != null) 'stressLevel': stressLevel,
        if (beforeMood != null) 'beforeMood': beforeMood,
        if (afterMood != null) 'afterMood': afterMood,
      },
    );
  }

  Future<Map<String, dynamic>> getBreathing({int limit = 20}) async {
    final userId = await _getUserId();
    final res = await _api.get('/wellness/breathing/$userId?limit=$limit', authenticated: true);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return res.map((k, v) => MapEntry(k.toString(), v));
    throw const ApiException(message: 'Unexpected breathing response');
  }

  // Nudges
  Future<Map<String, dynamic>> createNudge({
    required String title,
    String? description,
    required String type,
    required String scheduledTime,
    List<String>? repeatDays,
    String? priority,
  }) async {
    final userId = await _getUserId();
    final res = await _api.post(
      '/wellness/nudges',
      authenticated: true,
      body: {
        'userId': userId,
        'title': title,
        'description': description ?? '',
        'type': type,
        'scheduledTime': scheduledTime,
        'repeatDays': repeatDays ?? [],
        'priority': priority ?? 'medium',
      },
    );
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return res.map((k, v) => MapEntry(k.toString(), v));
    throw const ApiException(message: 'Unexpected create nudge response');
  }

  Future<List<dynamic>> getNudges({bool active = true}) async {
    final userId = await _getUserId();
    final res = await _api.get('/wellness/nudges/$userId?active=$active', authenticated: true);
    if (res is Map && res['data'] is List) {
      return (res['data'] as List);
    }
    if (res is List) return res;
    return [];
  }

  Future<Map<String, dynamic>> updateNudge(String id, Map<String, dynamic> update) async {
    final res = await _api.put('/wellness/nudges/$id', authenticated: true, body: update);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return res.map((k, v) => MapEntry(k.toString(), v));
    throw const ApiException(message: 'Unexpected update nudge response');
  }

  Future<void> deleteNudge(String id) async {
    await _api.delete('/wellness/nudges/$id', authenticated: true);
  }

  // Mood
  Future<void> logMood({
    required int mood,
    List<String>? emotions,
    String? notes,
    List<String>? triggers,
    List<String>? activities,
  }) async {
    final userId = await _getUserId();
    await _api.post(
      '/wellness/mood',
      authenticated: true,
      body: {
        'userId': userId,
        'mood': mood,
        'emotions': emotions ?? [],
        'notes': notes ?? '',
        'triggers': triggers ?? [],
        'activities': activities ?? [],
      },
    );
  }

  Future<Map<String, dynamic>> getMood({int days = 30, int limit = 50}) async {
    final userId = await _getUserId();
    final res = await _api.get('/wellness/mood/$userId?days=$days&limit=$limit', authenticated: true);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return res.map((k, v) => MapEntry(k.toString(), v));
    throw const ApiException(message: 'Unexpected mood response');
  }
}

// Voice / Therapeutic Chat Service
class VoiceService {
  final ApiClient _api;

  VoiceService({ApiClient? apiClient, TokenStore? tokenStore})
      : _api = apiClient ??
            ApiClient(
              baseUrl: ApiConfig.baseUrl,
              tokenStore: tokenStore ?? SharedPrefsTokenStore(),
            );

  Future<String> therapeuticReply(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw const ApiException(message: 'Message cannot be empty');
    }

    final res = await _api.post(
      '/voice/therapeutic',
      authenticated: true,
      body: {'message': trimmed},
    );

    if (res is Map) {
      final reply = res['reply'];
      if (reply is String && reply.trim().isNotEmpty) {
        return reply.trim();
      }
    }

    throw const ApiException(message: 'Unexpected therapeutic response');
  }
}

class VoiceJournalStart {
  final String callId;
  final String accessToken;

  const VoiceJournalStart({required this.callId, required this.accessToken});
}

class VoiceJournalStatus {
  final String status;
  final String? entryId;

  const VoiceJournalStatus({required this.status, this.entryId});

  bool get isCompleted => status == 'completed' && (entryId ?? '').isNotEmpty;
}

// Voice Journal (Retell + n8n orchestrated) Service
class VoiceJournalService {
  static const String _userKey = 'current_user';
  final ApiClient _api;

  VoiceJournalService({ApiClient? apiClient, TokenStore? tokenStore})
      : _api = apiClient ??
            ApiClient(
              baseUrl: ApiConfig.baseUrl,
              tokenStore: tokenStore ?? SharedPrefsTokenStore(),
            );

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null || userJson.isEmpty) {
      throw const ApiException(message: 'Not logged in');
    }
    final map = json.decode(userJson);
    final id = (map is Map ? (map['id'] ?? '').toString() : '');
    if (id.isEmpty) {
      throw const ApiException(message: 'Missing user id');
    }
    return id;
  }

  Future<VoiceJournalStart> startVoiceJournalCall() async {
    final userId = await _getUserId();
    final res = await _api.post(
      '/journal/voice/start',
      authenticated: true,
      body: {'userId': userId},
    );

    if (res is Map && res['data'] is Map) {
      final data = res['data'] as Map;
      final callId = (data['callId'] ?? '').toString();
      final accessToken = (data['accessToken'] ?? '').toString();
      if (callId.isNotEmpty && accessToken.isNotEmpty) {
        return VoiceJournalStart(callId: callId, accessToken: accessToken);
      }
    }

    throw const ApiException(message: 'Unexpected voice journal start response');
  }

  Future<VoiceJournalStatus> getVoiceJournalStatus(String callId) async {
    final trimmed = callId.trim();
    if (trimmed.isEmpty) {
      throw const ApiException(message: 'Missing call id');
    }

    final res = await _api.get(
      '/journal/voice/status/$trimmed',
      authenticated: true,
    );

    if (res is Map) {
      final status = (res['status'] ?? '').toString();
      final entryId = (res['entryId'] ?? '').toString();
      if (status.isNotEmpty) {
        return VoiceJournalStatus(status: status, entryId: entryId.isEmpty ? null : entryId);
      }
    }

    throw const ApiException(message: 'Unexpected voice journal status response');
  }
}

// Analytics Service
class AnalyticsService {
  final TaskService _taskService;
  final EmotionService _emotionService;
  final JournalService _journalService;

  AnalyticsService({
    required TaskService taskService,
    required EmotionService emotionService,
    required JournalService journalService,
  }) : _taskService = taskService,
       _emotionService = emotionService,
       _journalService = journalService;

  Future<AnalyticsData> getAnalyticsData() async {
    final tasks = await _taskService.getTasks();
    final emotions = await _emotionService.getEmotions();
    final journalEntries = await _journalService.getJournalEntries();

    // Calculate analytics
    final happyDays = emotions
        .where((e) => e.emotion.toLowerCase().contains('happy'))
        .length;
    final tasksCompleted = tasks
        .where((t) => t.status == TaskStatus.completed)
        .length;
    final currentStreak = _calculateStreak(emotions);

    return AnalyticsData(
      happyDays: happyDays,
      tasksCompleted: tasksCompleted,
      journalEntries: journalEntries.length,
      currentStreak: currentStreak,
      recentEmotions: emotions.take(5).toList(),
      recentTasks: tasks.take(5).toList(),
    );
  }

  int _calculateStreak(List<Emotion> emotions) {
    if (emotions.isEmpty) return 0;

    // Simple streak calculation - consecutive days with emotions logged
    final sortedEmotions = emotions
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    int streak = 0;
    DateTime currentDate = DateTime.now();

    for (final emotion in sortedEmotions) {
      if (_isSameDay(emotion.timestamp, currentDate)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
