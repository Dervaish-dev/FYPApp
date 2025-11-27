import 'package:equatable/equatable.dart';
import 'package:neurocompanion_flutter/models/models.dart';
import 'package:neurocompanion_flutter/models/task.dart';

// Authentication Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const RegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

class LogoutRequested extends AuthEvent {}

class AuthStatusChanged extends AuthEvent {
  final User? user;

  const AuthStatusChanged({this.user});

  @override
  List<Object?> get props => [user];
}

// Authentication States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final User user;

  const AuthSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

// Task Events
abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {}

class AddTask extends TaskEvent {
  final Task task;

  const AddTask({required this.task});

  @override
  List<Object?> get props => [task];
}

class UpdateTaskStatus extends TaskEvent {
  final String taskId;
  final TaskStatus status;

  const UpdateTaskStatus({required this.taskId, required this.status});

  @override
  List<Object?> get props => [taskId, status];
}

class DeleteTask extends TaskEvent {
  final String taskId;

  const DeleteTask({required this.taskId});

  @override
  List<Object?> get props => [taskId];
}

// Task States
abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<Task> tasks;

  const TaskLoaded({required this.tasks});

  @override
  List<Object?> get props => [tasks];
}

class TaskError extends TaskState {
  final String message;

  const TaskError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Emotion Events
abstract class EmotionEvent extends Equatable {
  const EmotionEvent();

  @override
  List<Object?> get props => [];
}

class LoadEmotions extends EmotionEvent {}

class AddEmotion extends EmotionEvent {
  final String emotion;
  final int intensity;
  final String? note;

  const AddEmotion({required this.emotion, required this.intensity, this.note});

  @override
  List<Object?> get props => [emotion, intensity, note];
}

class DeleteEmotion extends EmotionEvent {
  final String emotionId;

  const DeleteEmotion({required this.emotionId});

  @override
  List<Object?> get props => [emotionId];
}

// Emotion States
abstract class EmotionState extends Equatable {
  const EmotionState();

  @override
  List<Object?> get props => [];
}

class EmotionInitial extends EmotionState {}

class EmotionLoading extends EmotionState {}

class EmotionLoaded extends EmotionState {
  final List<Emotion> emotions;

  const EmotionLoaded({required this.emotions});

  @override
  List<Object?> get props => [emotions];
}

class EmotionError extends EmotionState {
  final String message;

  const EmotionError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Journal Events
abstract class JournalEvent extends Equatable {
  const JournalEvent();

  @override
  List<Object?> get props => [];
}

class LoadJournalEntries extends JournalEvent {}

class AddJournalEntry extends JournalEvent {
  final String content;
  final String? emotion;

  const AddJournalEntry({required this.content, this.emotion});

  @override
  List<Object?> get props => [content, emotion];
}

class UpdateJournalEntry extends JournalEvent {
  final String entryId;
  final String content;

  const UpdateJournalEntry({required this.entryId, required this.content});

  @override
  List<Object?> get props => [entryId, content];
}

class DeleteJournalEntry extends JournalEvent {
  final String entryId;

  const DeleteJournalEntry({required this.entryId});

  @override
  List<Object?> get props => [entryId];
}

// Journal States
abstract class JournalState extends Equatable {
  const JournalState();

  @override
  List<Object?> get props => [];
}

class JournalInitial extends JournalState {}

class JournalLoading extends JournalState {}

class JournalLoaded extends JournalState {
  final List<JournalEntry> entries;

  const JournalLoaded({required this.entries});

  @override
  List<Object?> get props => [entries];
}

class JournalError extends JournalState {
  final String message;

  const JournalError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Analytics Events
abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAnalytics extends AnalyticsEvent {}

// Analytics States
abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final AnalyticsData data;

  const AnalyticsLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError({required this.message});

  @override
  List<Object?> get props => [message];
}
