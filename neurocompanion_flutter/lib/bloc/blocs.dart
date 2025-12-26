import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/services/services.dart';
import 'package:neurocompanion_flutter/services/database_service.dart';
import 'package:neurocompanion_flutter/models/models.dart';

// Authentication BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
    : _authService = authService,
      super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<Verify2FARequested>(_onVerify2FARequested);
    on<Toggle2FARequested>(_onToggle2FARequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<VerifyResetOTPRequested>(_onVerifyResetOTPRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        emit(AuthSuccess(user: user));
      } else {
        emit(AuthInitial());
      }
    } catch (_) {
      emit(AuthInitial());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Clear any cached data from previous user before logging in
      try {
        final DatabaseService dbService = DatabaseService();
        await dbService.clearAllData();
      } catch (e) {
        print('Error clearing database before login: $e');
      }
      
      final response = await _authService.login(event.email, event.password);
      
      // Check if 2FA is required
      if (response['requires2FA'] == true) {
        emit(Auth2FARequired(userId: response['userId'] ?? ''));
        return;
      }
      
      // The user is already a User object, not a map
      final user = response['user'] as User;
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
    
    // Clear all cached data from database
    try {
      final DatabaseService dbService = DatabaseService();
      await dbService.clearAllData();
    } catch (e) {
      print('Error clearing database on logout: $e');
    }
    
    emit(AuthInitial());
  }

  void _onAuthStatusChanged(AuthStatusChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(AuthSuccess(user: event.user!));
    } else {
      emit(AuthInitial());
    }
  }

  Future<void> _onVerify2FARequested(
    Verify2FARequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authService.verify2FA(event.userId, event.otp);
      emit(AuthSuccess(user: user));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onToggle2FARequested(
    Toggle2FARequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final result = await _authService.toggle2FA();
      emit(Auth2FAEnabled(
        enabled: result['twoFactorEnabled'] ?? false,
        message: result['message'] ?? '2FA updated',
      ));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authService.forgotPassword(event.email);
      emit(PasswordResetOTPSent(email: event.email));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onVerifyResetOTPRequested(
    VerifyResetOTPRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authService.verifyResetOTP(event.email, event.otp);
      emit(PasswordResetOTPVerified(email: event.email, otp: event.otp));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authService.resetPassword(event.email, event.otp, event.newPassword);
      emit(const PasswordResetSuccess());
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
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
    on<UpdateTask>(_onUpdateTask);
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

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    try {
      await _taskService.updateTask(event.task);
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
  final AuthService _authService;

  JournalBloc({
    required JournalService journalService,
    required AuthService authService,
  })  : _journalService = journalService,
        _authService = authService,
        super(JournalInitial()) {
    on<LoadJournalEntries>(_onLoadJournalEntries);
    on<CreateJournalEntry>(_onCreateJournalEntry);
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
      var userId = _authService.currentUser?.id;
      
      // Try to get user if not cached
      if (userId == null) {
        final user = await _authService.getCurrentUser();
        userId = user?.id;
      }
      
      if (userId == null) {
        emit(const JournalError(message: 'User not authenticated'));
        return;
      }
      final entries = await _journalService.listByUser(userId);
      emit(JournalLoaded(entries: entries));
    } catch (e) {
      emit(JournalError(message: e.toString()));
    }
  }

  Future<void> _onCreateJournalEntry(
    CreateJournalEntry event,
    Emitter<JournalState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is JournalLoaded) {
        emit(JournalLoading());
        final newEntry = await _journalService.create(
          userId: event.userId,
          content: event.content,
          mood: event.mood,
          tags: event.tags,
        );
        final updatedEntries = [newEntry, ...currentState.entries];
        emit(JournalLoaded(entries: updatedEntries));
      }
    } catch (e) {
      print('❌ Journal creation error: $e');
      String errorMessage = 'Failed to save journal entry';
      if (e.toString().contains('502')) {
        errorMessage = 'Server temporarily unavailable. Please try again.';
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        errorMessage = 'Please log in again';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout. Check your internet.';
      }
      emit(JournalError(message: errorMessage));
      add(LoadJournalEntries());
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
      final currentState = state;
      if (currentState is JournalLoaded) {
        emit(JournalLoading());
        final updatedEntry = await _journalService.update(
          event.entryId,
          event.content,
        );
        final updatedEntries = currentState.entries
            .map((entry) => entry.id == event.entryId ? updatedEntry : entry)
            .toList();
        emit(JournalLoaded(entries: updatedEntries));
      }
    } catch (e) {
      emit(JournalError(message: e.toString()));
      add(LoadJournalEntries());
    }
  }

  Future<void> _onDeleteJournalEntry(
    DeleteJournalEntry event,
    Emitter<JournalState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is JournalLoaded) {
        emit(JournalLoading());
        await _journalService.delete(event.entryId);
        final updatedEntries = currentState.entries
            .where((entry) => entry.id != event.entryId)
            .toList();
        emit(JournalLoaded(entries: updatedEntries));
      }
    } catch (e) {
      emit(JournalError(message: e.toString()));
      add(LoadJournalEntries());
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
