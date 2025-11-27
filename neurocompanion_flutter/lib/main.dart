import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/bloc/blocs.dart';
import 'package:neurocompanion_flutter/services/services.dart';
import 'package:neurocompanion_flutter/screens/login_screen.dart';
import 'package:neurocompanion_flutter/screens/register_screen.dart';
import 'package:neurocompanion_flutter/screens/main_layout.dart';

void main() {
  runApp(const NeuroCompanionApp());
}

class NeuroCompanionApp extends StatelessWidget {
  const NeuroCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final authService = AuthService();
    final taskService = TaskService();
    final emotionService = EmotionService();
    final journalService = JournalService();
    final analyticsService = AnalyticsService(
      taskService: taskService,
      emotionService: emotionService,
      journalService: journalService,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authService: authService),
        ),
        BlocProvider<TaskBloc>(
          create: (context) => TaskBloc(taskService: taskService),
        ),
        BlocProvider<EmotionBloc>(
          create: (context) => EmotionBloc(emotionService: emotionService),
        ),
        BlocProvider<JournalBloc>(
          create: (context) => JournalBloc(journalService: journalService),
        ),
        BlocProvider<AnalyticsBloc>(
          create: (context) =>
              AnalyticsBloc(analyticsService: analyticsService),
        ),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final theme = themeProvider.currentTheme;

          return MaterialApp(
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
                  return const MainLayout();
                } else {
                  return const LoginScreen();
                }
              },
            ),
            routes: {
              '/register': (context) => const RegisterScreen(),
              '/main': (context) => const MainLayout(),
            },
          );
        },
      ),
    );
  }
}
