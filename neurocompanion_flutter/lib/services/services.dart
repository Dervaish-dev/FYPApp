import 'package:neurocompanion_flutter/models/models.dart';
import 'package:neurocompanion_flutter/models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

// Authentication Service
class AuthService {
  static const String _userKey = 'current_user';

  Future<User> login(String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // Mock authentication - in real app, this would call Firebase/API
    if (email.isNotEmpty && password.length >= 6) {
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: email.split('@')[0],
        email: email,
        createdAt: DateTime.now(),
      );

      await _saveUser(user);
      return user;
    } else {
      throw Exception('Invalid credentials');
    }
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      final userMap = json.decode(userJson);
      return User(
        id: userMap['id'],
        name: userMap['name'],
        email: userMap['email'],
        createdAt: DateTime.parse(userMap['createdAt']),
      );
    }
    return null;
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
  static const String _tasksKey = 'tasks';

  Future<List<Task>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList(_tasksKey) ?? [];

    return tasksJson.map((json) {
      final taskMap = jsonDecode(json);
      return Task(
        id: taskMap['id'],
        title: taskMap['title'],
        description: taskMap['description'],
        priority: TaskPriority.values.firstWhere(
          (e) => e.name == taskMap['priority'],
          orElse: () => TaskPriority.medium,
        ),
        status: TaskStatus.values.firstWhere(
          (e) => e.name == taskMap['status'],
          orElse: () => TaskStatus.todo,
        ),
        dueDate: taskMap['dueDate'] != null
            ? DateTime.parse(taskMap['dueDate'])
            : null,
        reminderTime: taskMap['reminderTime'] != null
            ? TimeOfDay(
                hour: int.parse(taskMap['reminderTime'].split(':')[0]),
                minute: int.parse(taskMap['reminderTime'].split(':')[1]),
              )
            : null,
        createdAt: DateTime.parse(taskMap['createdAt']),
        completedAt: taskMap['completedAt'] != null
            ? DateTime.parse(taskMap['completedAt'])
            : null,
      );
    }).toList();
  }

  Future<void> addTask(Task task) async {
    final tasks = await getTasks();
    tasks.add(task);
    await _saveTasks(tasks);
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final tasks = await getTasks();
    final taskIndex = tasks.indexWhere((task) => task.id == taskId);

    if (taskIndex != -1) {
      tasks[taskIndex] = tasks[taskIndex].copyWith(
        status: status,
        completedAt: status == TaskStatus.completed ? DateTime.now() : null,
      );
      await _saveTasks(tasks);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = await getTasks();
    tasks.removeWhere((task) => task.id == taskId);
    await _saveTasks(tasks);
  }

  Future<void> _saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks.map((task) => jsonEncode(task.toJson())).toList();

    await prefs.setStringList(_tasksKey, tasksJson);
  }
}

// Emotion Service
class EmotionService {
  static const String _emotionsKey = 'emotions';

  Future<List<Emotion>> getEmotions() async {
    final prefs = await SharedPreferences.getInstance();
    final emotionsJson = prefs.getStringList(_emotionsKey) ?? [];

    return emotionsJson.map((json) {
      final emotionMap = jsonDecode(json);
      return Emotion(
        id: emotionMap['id'],
        emotion: emotionMap['emotion'],
        intensity: emotionMap['intensity'],
        note: emotionMap['note'],
        timestamp: DateTime.parse(emotionMap['timestamp']),
      );
    }).toList();
  }

  Future<void> addEmotion(String emotion, int intensity, String? note) async {
    final emotions = await getEmotions();
    final newEmotion = Emotion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      emotion: emotion,
      intensity: intensity,
      note: note,
      timestamp: DateTime.now(),
    );

    emotions.add(newEmotion);
    await _saveEmotions(emotions);
  }

  Future<void> deleteEmotion(String emotionId) async {
    final emotions = await getEmotions();
    emotions.removeWhere((emotion) => emotion.id == emotionId);
    await _saveEmotions(emotions);
  }

  Future<void> _saveEmotions(List<Emotion> emotions) async {
    final prefs = await SharedPreferences.getInstance();
    final emotionsJson = emotions
        .map(
          (emotion) => jsonEncode({
            'id': emotion.id,
            'emotion': emotion.emotion,
            'intensity': emotion.intensity,
            'note': emotion.note,
            'timestamp': emotion.timestamp.toIso8601String(),
          }),
        )
        .toList();

    await prefs.setStringList(_emotionsKey, emotionsJson);
  }
}

// Journal Service
class JournalService {
  static const String _journalKey = 'journal_entries';

  Future<List<JournalEntry>> getJournalEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList(_journalKey) ?? [];

    return entriesJson.map((json) {
      final entryMap = jsonDecode(json);
      return JournalEntry(
        id: entryMap['id'],
        content: entryMap['content'],
        emotion: entryMap['emotion'],
        createdAt: DateTime.parse(entryMap['createdAt']),
        updatedAt: entryMap['updatedAt'] != null
            ? DateTime.parse(entryMap['updatedAt'])
            : null,
      );
    }).toList();
  }

  Future<void> addJournalEntry(String content, String? emotion) async {
    final entries = await getJournalEntries();
    final newEntry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      emotion: emotion,
      createdAt: DateTime.now(),
    );

    entries.add(newEntry);
    await _saveJournalEntries(entries);
  }

  Future<void> updateJournalEntry(String entryId, String content) async {
    final entries = await getJournalEntries();
    final entryIndex = entries.indexWhere((entry) => entry.id == entryId);

    if (entryIndex != -1) {
      entries[entryIndex] = entries[entryIndex].copyWith(
        content: content,
        updatedAt: DateTime.now(),
      );
      await _saveJournalEntries(entries);
    }
  }

  Future<void> deleteJournalEntry(String entryId) async {
    final entries = await getJournalEntries();
    entries.removeWhere((entry) => entry.id == entryId);
    await _saveJournalEntries(entries);
  }

  Future<void> _saveJournalEntries(List<JournalEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = entries
        .map(
          (entry) => jsonEncode({
            'id': entry.id,
            'content': entry.content,
            'emotion': entry.emotion,
            'createdAt': entry.createdAt.toIso8601String(),
            'updatedAt': entry.updatedAt?.toIso8601String(),
          }),
        )
        .toList();

    await prefs.setStringList(_journalKey, entriesJson);
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
