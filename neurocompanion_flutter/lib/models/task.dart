import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum TaskStatus { todo, inProgress, completed }

enum TaskPriority { low, medium, high, urgent }

class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final TimeOfDay? reminderTime;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.dueDate,
    this.reminderTime,
    required this.createdAt,
    this.completedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    TimeOfDay? reminderTime,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    priority,
    status,
    dueDate,
    reminderTime,
    createdAt,
    completedAt,
  ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'dueDate': dueDate?.toIso8601String(),
      'reminderTime': reminderTime != null
          ? '${reminderTime!.hour}:${reminderTime!.minute}'
          : null,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.todo,
      ),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      reminderTime: json['reminderTime'] != null
          ? TimeOfDay(
              hour: int.parse(json['reminderTime'].split(':')[0]),
              minute: int.parse(json['reminderTime'].split(':')[1]),
            )
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}
