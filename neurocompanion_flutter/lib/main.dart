import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/bloc/blocs.dart';
import 'package:neurocompanion_flutter/services/api_client.dart';
import 'package:neurocompanion_flutter/services/api_config.dart';
import 'package:neurocompanion_flutter/services/invite_service.dart';
import 'package:neurocompanion_flutter/services/preferences_service.dart';
import 'package:neurocompanion_flutter/services/token_store.dart';
import 'package:neurocompanion_flutter/services/services.dart';
import 'package:neurocompanion_flutter/services/caregiver_service.dart';
import 'package:neurocompanion_flutter/screens/login_screen.dart';
import 'package:neurocompanion_flutter/screens/register_screen.dart';
import 'package:neurocompanion_flutter/screens/main_layout.dart';
import 'package:neurocompanion_flutter/screens/caregiver_layout_screen.dart';

void main() {
  runApp(const NeuroCompanionApp());
}

class NeuroCompanionApp extends StatelessWidget {
  const NeuroCompanionApp({super.key});

  String _fromBackendThemeKey(String backendTheme) {
    switch (backendTheme) {
      case 'dark':
        return 'midnight';
      case 'ocean':
      case 'coral':
      case 'mint':
      case 'lavender':
        return backendTheme;
      default:
        return 'ocean';
    }
  }

  Future<void> _applyUserPreferences(
    String userId,
    PreferencesService preferencesService,
    ThemeProvider themeProvider,
  ) async {
    try {
      final prefs = await preferencesService.fetch(userId);
      final mappedTheme = _fromBackendThemeKey(prefs.defaultTheme);
      await themeProvider.setTheme(mappedTheme);
      await themeProvider.setAdaptiveMode(prefs.adaptiveMode);
    } catch (_) {
      // Best-effort: keep local preferences if backend fetch fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize API foundation (Week 1–2)
    final tokenStore = SharedPrefsTokenStore();
    final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl, tokenStore: tokenStore);
    final inviteService = InviteService(apiClient: apiClient);
    final caregiverService = CaregiverService(apiClient: apiClient);

    // Initialize services
    final authService = AuthService(tokenStore: tokenStore, apiClient: apiClient);
    final preferencesService = PreferencesService(apiClient: apiClient);
    final taskService = TaskService(apiClient: apiClient, tokenStore: tokenStore);
    final emotionService = EmotionService(apiClient: apiClient, tokenStore: tokenStore);
    final journalService = JournalService(apiClient: apiClient, tokenStore: tokenStore);
    final wellnessService = WellnessService(apiClient: apiClient, tokenStore: tokenStore);
    final voiceService = VoiceService(apiClient: apiClient, tokenStore: tokenStore);
    final voiceJournalService = VoiceJournalService(apiClient: apiClient, tokenStore: tokenStore);
    final analyticsService = AnalyticsService(
      taskService: taskService,
      emotionService: emotionService,
      journalService: journalService,
    );

    return MultiProvider(
      providers: [
        Provider<TokenStore>.value(value: tokenStore),
        Provider<ApiClient>.value(value: apiClient),
        Provider<InviteService>.value(value: inviteService),
        Provider<CaregiverService>.value(value: caregiverService),
        Provider<AuthService>.value(value: authService),
        Provider<PreferencesService>.value(value: preferencesService),
        Provider<WellnessService>.value(value: wellnessService),
        Provider<VoiceService>.value(value: voiceService),
        Provider<VoiceJournalService>.value(value: voiceJournalService),
        Provider<EmotionService>.value(value: emotionService),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: MultiBlocProvider(
        providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authService: authService)..add(const AppStarted()),
        ),
        BlocProvider<TaskBloc>(
          create: (context) => TaskBloc(taskService: taskService),
        ),
        BlocProvider<EmotionBloc>(
          create: (context) => EmotionBloc(emotionService: emotionService),
        ),
        BlocProvider<JournalBloc>(
          create: (context) => JournalBloc(
            journalService: journalService,
            authService: authService,
          ),
        ),
        BlocProvider<AnalyticsBloc>(
          create: (context) =>
              AnalyticsBloc(analyticsService: analyticsService),
        ),
        ],
        child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final theme = themeProvider.currentTheme;

          return BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) {
              // Listen when state changes from AuthSuccess to AuthInitial (logout)
              // or when user ID changes (different user logged in)
              if (previous is AuthSuccess && current is AuthInitial) return true;
              if (current is! AuthSuccess) return false;
              if (previous is! AuthSuccess) return true;
              return previous.user.id != current.user.id;
            },
            listener: (context, state) {
              if (state is AuthSuccess) {
                final preferencesService = context.read<PreferencesService>();
                final themeProvider = context.read<ThemeProvider>();
                _applyUserPreferences(state.user.id, preferencesService, themeProvider);
              }
            },
            child: MaterialApp(
            title: 'NeuroCompanion',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'Poppins',
              scaffoldBackgroundColor: theme.background,
              appBarTheme: AppBarTheme(
                backgroundColor: theme.card,
                foregroundColor: theme.text,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(
                  color: theme.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              cardTheme: CardThemeData(
                color: theme.card,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.border),
                ),
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: theme.background,
                labelStyle: TextStyle(color: theme.text.withOpacity(0.7)),
                hintStyle: TextStyle(color: theme.text.withOpacity(0.5)),
                prefixIconColor: theme.text.withOpacity(0.7),
                suffixIconColor: theme.text.withOpacity(0.7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primary, width: 2),
                ),
              ),
            ),
            home: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthSuccess) {
                  if (state.user.role == 'caregiver') {
                    return const CaregiverLayoutScreen();
                  }
                  return const MainLayout();
                } else {
                  return const LoginScreen();
                }
              },
            ),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/main': (context) => const MainLayout(),
            },
            ),
          );
        },
        ),
      ),
    );
  }
}
