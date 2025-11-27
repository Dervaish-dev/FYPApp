import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/services/services.dart';

// Authentication BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
    : _authService = authService,
      super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthStatusChanged>(_onAuthStatusChanged);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authService.login(event.email, event.password);
      emit(AuthSuccess(user: user));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authService.register(
        event.name,
        event.email,
        event.password,
      );
      emit(AuthSuccess(user: user));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.logout();
    emit(AuthInitial());
  }

  void _onAuthStatusChanged(AuthStatusChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(AuthSuccess(user: event.user!));
    } else {
      emit(AuthInitial());
    }
  }
}

// Task BLoC
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskService _taskService;

  TaskBloc({required TaskService taskService})
    : _taskService = taskService,
      super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<UpdateTaskStatus>(_onUpdateTaskStatus);
    on<DeleteTask>(_onDeleteTask);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final tasks = await _taskService.getTasks();
      emit(TaskLoaded(tasks: tasks));
    } catch (e) {
      emit(TaskError(message: e.toString()));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    try {
      await _taskService.addTask(event.task);
      add(LoadTasks());
    } catch (e) {
      emit(TaskError(message: e.toString()));
    }
  }

  Future<void> _onUpdateTaskStatus(
    UpdateTaskStatus event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _taskService.updateTaskStatus(event.taskId, event.status);
      add(LoadTasks());
    } catch (e) {
      emit(TaskError(message: e.toString()));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      await _taskService.deleteTask(event.taskId);
      add(LoadTasks());
    } catch (e) {
      emit(TaskError(message: e.toString()));
    }
  }
}

// Emotion BLoC
class EmotionBloc extends Bloc<EmotionEvent, EmotionState> {
  final EmotionService _emotionService;

  EmotionBloc({required EmotionService emotionService})
    : _emotionService = emotionService,
      super(EmotionInitial()) {
    on<LoadEmotions>(_onLoadEmotions);
    on<AddEmotion>(_onAddEmotion);
    on<DeleteEmotion>(_onDeleteEmotion);
  }

  Future<void> _onLoadEmotions(
    LoadEmotions event,
    Emitter<EmotionState> emit,
  ) async {
    emit(EmotionLoading());
    try {
      final emotions = await _emotionService.getEmotions();
      emit(EmotionLoaded(emotions: emotions));
    } catch (e) {
      emit(EmotionError(message: e.toString()));
    }
  }

  Future<void> _onAddEmotion(
    AddEmotion event,
    Emitter<EmotionState> emit,
  ) async {
    try {
      await _emotionService.addEmotion(
        event.emotion,
        event.intensity,
        event.note,
      );
      add(LoadEmotions());
    } catch (e) {
      emit(EmotionError(message: e.toString()));
    }
  }

  Future<void> _onDeleteEmotion(
    DeleteEmotion event,
    Emitter<EmotionState> emit,
  ) async {
    try {
      await _emotionService.deleteEmotion(event.emotionId);
      add(LoadEmotions());
    } catch (e) {
      emit(EmotionError(message: e.toString()));
    }
  }
}

// Journal BLoC
class JournalBloc extends Bloc<JournalEvent, JournalState> {
  final JournalService _journalService;

  JournalBloc({required JournalService journalService})
    : _journalService = journalService,
      super(JournalInitial()) {
    on<LoadJournalEntries>(_onLoadJournalEntries);
    on<AddJournalEntry>(_onAddJournalEntry);
    on<UpdateJournalEntry>(_onUpdateJournalEntry);
    on<DeleteJournalEntry>(_onDeleteJournalEntry);
  }

  Future<void> _onLoadJournalEntries(
    LoadJournalEntries event,
    Emitter<JournalState> emit,
  ) async {
    emit(JournalLoading());
    try {
      final entries = await _journalService.getJournalEntries();
      emit(JournalLoaded(entries: entries));
    } catch (e) {
      emit(JournalError(message: e.toString()));
    }
  }

  Future<void> _onAddJournalEntry(
    AddJournalEntry event,
    Emitter<JournalState> emit,
  ) async {
    try {
      await _journalService.addJournalEntry(event.content, event.emotion);
      add(LoadJournalEntries());
    } catch (e) {
      emit(JournalError(message: e.toString()));
    }
  }

  Future<void> _onUpdateJournalEntry(
    UpdateJournalEntry event,
    Emitter<JournalState> emit,
  ) async {
    try {
      await _journalService.updateJournalEntry(event.entryId, event.content);
      add(LoadJournalEntries());
    } catch (e) {
      emit(JournalError(message: e.toString()));
    }
  }

  Future<void> _onDeleteJournalEntry(
    DeleteJournalEntry event,
    Emitter<JournalState> emit,
  ) async {
    try {
      await _journalService.deleteJournalEntry(event.entryId);
      add(LoadJournalEntries());
    } catch (e) {
      emit(JournalError(message: e.toString()));
    }
  }
}

// Analytics BLoC
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsService _analyticsService;

  AnalyticsBloc({required AnalyticsService analyticsService})
    : _analyticsService = analyticsService,
      super(AnalyticsInitial()) {
    on<LoadAnalytics>(_onLoadAnalytics);
  }

  Future<void> _onLoadAnalytics(
    LoadAnalytics event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _analyticsService.getAnalyticsData();
      emit(AnalyticsLoaded(data: data));
    } catch (e) {
      emit(AnalyticsError(message: e.toString()));
    }
  }
}
