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
import 'package:neurocompanion_flutter/screens/voice_screen.dart';
import 'package:neurocompanion_flutter/screens/caregiver_screen.dart';
import 'package:neurocompanion_flutter/screens/wellness_screen.dart';
import 'package:neurocompanion_flutter/screens/settings_screen.dart';

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
    const VoiceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.card,
            elevation: 0,
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
              IconButton(
                icon: Icon(Icons.settings, color: theme.text),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ],
          ),
          drawer: _buildDrawer(theme),
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
                    _buildNavItem(0, Icons.dashboard, 'Dashboard'),
                    _buildNavItem(1, Icons.favorite, 'Emotions'),
                    _buildNavItem(2, Icons.check_box, 'Tasks'),
                    _buildNavItem(3, Icons.book, 'Journal'),
                    _buildNavItem(4, Icons.mic, 'Voice'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(AppTheme theme) {
    return Drawer(
      backgroundColor: theme.card,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primary, theme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'NeuroCompanion',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your mental health companion',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Drawer Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    theme,
                    Icons.dashboard,
                    'Dashboard',
                    () => _navigateToScreen(0),
                  ),
                  _buildDrawerItem(
                    theme,
                    Icons.favorite,
                    'Emotions',
                    () => _navigateToScreen(1),
                  ),
                  _buildDrawerItem(
                    theme,
                    Icons.check_box,
                    'Tasks',
                    () => _navigateToScreen(2),
                  ),
                  _buildDrawerItem(
                    theme,
                    Icons.book,
                    'Journal',
                    () => _navigateToScreen(3),
                  ),
                  _buildDrawerItem(
                    theme,
                    Icons.mic,
                    'Voice Assistant',
                    () => _navigateToScreen(4),
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    theme,
                    Icons.bar_chart,
                    'Analytics',
                    () => _navigateToAnalytics(),
                  ),
                  _buildDrawerItem(
                    theme,
                    Icons.people,
                    'Caregiver Portal',
                    () => _navigateToCaregiver(),
                  ),
                  _buildDrawerItem(
                    theme,
                    Icons.spa,
                    'Wellness',
                    () => _navigateToWellness(),
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    theme,
                    Icons.settings,
                    'Settings',
                    () => _navigateToSettings(),
                  ),
                  _buildDrawerItem(
                    theme,
                    Icons.logout,
                    'Logout',
                    () => _handleLogout(),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    AppTheme theme,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : theme.primary),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : theme.text,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        onTap();
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
                      fontSize: 12,
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

  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
    );
  }

  void _navigateToCaregiver() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CaregiverScreen()),
    );
  }

  void _navigateToWellness() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WellnessScreen()),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
