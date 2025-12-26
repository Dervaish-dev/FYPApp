import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/bloc/blocs.dart';
import 'package:neurocompanion_flutter/screens/dashboard_screen.dart';
import 'package:neurocompanion_flutter/screens/emotions_screen.dart';
import 'package:neurocompanion_flutter/screens/tasks_screen.dart';
import 'package:neurocompanion_flutter/screens/journal_screen.dart';
import 'package:neurocompanion_flutter/screens/analytics_screen.dart';
import 'package:neurocompanion_flutter/screens/breathing_screen.dart';
import 'package:neurocompanion_flutter/screens/profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    DashboardScreen(onNavigateToScreen: _navigateToScreen),
    const EmotionsScreen(),
    const TasksScreen(),
    const JournalScreen(),
    const AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        final authState = context.watch<AuthBloc>().state;
        String userName = 'User';
        
        if (authState is AuthSuccess) {
          userName = authState.user.name ?? authState.user.email.split('@')[0];
        }

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.card,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.primary, theme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'NeuroCompanion',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              // Profile Dropdown
              PopupMenuButton<String>(
                offset: const Offset(0, 50),
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: theme.primary,
                    size: 20,
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, color: theme.text, size: 20),
                        const SizedBox(width: 12),
                        Text('Profile', style: TextStyle(color: theme.text)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'profile') {
                    _navigateToProfile();
                  } else if (value == 'logout') {
                    _handleLogout();
                  }
                },
                color: theme.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.border),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: theme.card,
              border: Border(top: BorderSide(color: theme.border)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home, 'Home'),
                    _buildNavItem(1, Icons.favorite, 'Mood'),
                    _buildNavItem(2, Icons.check_box, 'Tasks'),
                    _buildNavItem(3, Icons.book, 'Journal'),
                    _buildNavItem(4, Icons.bar_chart, 'Analytics'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        final isSelected = _currentIndex == index;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              final screenNames = ['Dashboard', 'Emotions', 'Tasks', 'Journal', 'Analytics'];
              print('📱 [NAVIGATION] Navigating to ${screenNames[index]}');
              setState(() {
                _currentIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? theme.primary
                        : theme.text.withOpacity(0.6),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? theme.primary
                          : theme.text.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToScreen(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToProfile() {
    print('👤 [NAVIGATION] Opening Profile Screen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _handleLogout() async {
    print('🚪 [AUTH] Logout requested');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final theme = themeProvider.currentTheme;
          return AlertDialog(
            backgroundColor: theme.card,
            title: Text('Logout', style: TextStyle(color: theme.text)),
            content: Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: theme.text),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Cancel', style: TextStyle(color: theme.text)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && mounted) {
      print('✅ [AUTH] Logout confirmed, clearing data...');
      // Dispatch logout event
      context.read<AuthBloc>().add(LogoutRequested());
      
      // Wait a frame for bloc to process
      await Future.delayed(const Duration(milliseconds: 100));
      
      print('🔐 [AUTH] Navigating to login screen');
      // Navigate to login screen and remove all previous routes
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }
}
