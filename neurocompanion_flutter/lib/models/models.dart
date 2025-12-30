import 'package:equatable/equatable.dart';
import 'package:neurocompanion_flutter/models/task.dart';

// User Model
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final int? age;
  final String? neurotype;
  final String? gender;
  final bool? twoFactorEnabled;
  final String role;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.age,
    this.neurotype,
    this.gender,
    this.twoFactorEnabled,
    this.role = 'patient',
  });

  @override
  List<Object?> get props => [id, name, email, createdAt, age, neurotype, gender, twoFactorEnabled, role];

  User copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
    int? age,
    String? neurotype,
    String? gender,
    bool? twoFactorEnabled,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      age: age ?? this.age,
      neurotype: neurotype ?? this.neurotype,
      gender: gender ?? this.gender,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      role: role ?? this.role,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      age: json['age'],
      neurotype: json['neurotype'],
      gender: json['gender'],
      twoFactorEnabled: json['twoFactorEnabled'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'age': age,
      'neurotype': neurotype,
      'gender': gender,
      'twoFactorEnabled': twoFactorEnabled,
    };
  }
}

// Task models are now in task.dart

// Emotion Model
class Emotion extends Equatable {
  final String id;
  final String emotion;
  final int intensity;
  final String? note;
  final DateTime timestamp;

  const Emotion({
    required this.id,
    required this.emotion,
    required this.intensity,
    this.note,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, emotion, intensity, note, timestamp];

  Emotion copyWith({
    String? id,
    String? emotion,
    int? intensity,
    String? note,
    DateTime? timestamp,
  }) {
    return Emotion(
      id: id ?? this.id,
      emotion: emotion ?? this.emotion,
      intensity: intensity ?? this.intensity,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

// Journal Entry Model
class JournalEntry extends Equatable {
  final String id;
  final String content;
  final String? emotion;
  final double emotionConfidence;
  final String? aiAnalysis;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const JournalEntry({
    required this.id,
    required this.content,
    this.emotion,
    this.emotionConfidence = 0.0,
    this.aiAnalysis,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, content, emotion, emotionConfidence, aiAnalysis, createdAt, updatedAt];

  JournalEntry copyWith({
    String? id,
    String? content,
    String? emotion,
    double? emotionConfidence,
    String? aiAnalysis,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      content: content ?? this.content,
      emotion: emotion ?? this.emotion,
      emotionConfidence: emotionConfidence ?? this.emotionConfidence,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Analytics Model
class AnalyticsData extends Equatable {
  final int happyDays;
  final int tasksCompleted;
  final int journalEntries;
  final int currentStreak;
  final List<Emotion> recentEmotions;
  final List<Task> recentTasks;

  const AnalyticsData({
    required this.happyDays,
    required this.tasksCompleted,
    required this.journalEntries,
    required this.currentStreak,
    required this.recentEmotions,
    required this.recentTasks,
  });

  @override
  List<Object?> get props => [
    happyDays,
    tasksCompleted,
    journalEntries,
    currentStreak,
    recentEmotions,
    recentTasks,
  ];

  AnalyticsData copyWith({
    int? happyDays,
    int? tasksCompleted,
    int? journalEntries,
    int? currentStreak,
    List<Emotion>? recentEmotions,
    List<Task>? recentTasks,
  }) {
    return AnalyticsData(
      happyDays: happyDays ?? this.happyDays,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      journalEntries: journalEntries ?? this.journalEntries,
      currentStreak: currentStreak ?? this.currentStreak,
      recentEmotions: recentEmotions ?? this.recentEmotions,
      recentTasks: recentTasks ?? this.recentTasks,
    );
  }
}
