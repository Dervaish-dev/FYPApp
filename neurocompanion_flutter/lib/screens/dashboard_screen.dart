import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/bloc/blocs.dart';
import 'package:neurocompanion_flutter/screens/caregiver_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigateToScreen;
  
  const DashboardScreen({
    super.key,
    required this.onNavigateToScreen,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when dashboard opens
    context.read<TaskBloc>().add(LoadTasks());
    context.read<EmotionBloc>().add(LoadEmotions());
    context.read<JournalBloc>().add(LoadJournalEntries());
    context.read<AnalyticsBloc>().add(LoadAnalytics());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with User Info
                  _buildHeader(theme),
                  const SizedBox(height: 24),

                  // Caregiver Reports Section
                  _buildCaregiverReports(theme),
                  const SizedBox(height: 24),

                  // Quick Actions Section
                  _buildQuickActions(theme),
                  const SizedBox(height: 24),

                  // Caregiver Portal Section
                  _buildCaregiverPortal(theme),
                ],
              ),
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(theme),
        );
      },
    );
  }

  Widget _buildHeader(AppTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo and App Info
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primary, theme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NeuroCompanion',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'AI Mental Health Companion',
                      style: TextStyle(
                        color: theme.text.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.person, color: theme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dervaish Abbas',
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'dervaishabbas@gmail.com',
                        style: TextStyle(
                          color: theme.text.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.settings,
                  color: theme.text.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaregiverReports(AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caregiver Reports',
          style: TextStyle(
            color: theme.text,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Single column layout for mobile
        Column(
          children: [
            _buildReportCard(
              theme,
              Icons.favorite_outline,
              '85%',
              'Mood Stability',
              'Maintain sleep schedule for continued stability.',
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildReportCard(
              theme,
              Icons.center_focus_strong,
              '72%',
              'Task Completion',
              'Great progress this week! Keep up the momentum.',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildReportCard(
              theme,
              Icons.notifications_outlined,
              '3',
              'Days',
              'Next caregiver review scheduled in 3 days.',
              Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportCard(
    AppTheme theme,
    IconData icon,
    String value,
    String label,
    String description,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: theme.text.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: theme.text,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Single column layout for mobile
        Column(
          children: [
            _buildActionCard(
              theme,
              Icons.favorite_outline,
              'Emotions',
              () => _navigateToScreen(1),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              theme,
              Icons.check_box_outlined,
              'Tasks',
              () => _navigateToScreen(2),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              theme,
              Icons.book_outlined,
              'Journal',
              () => _navigateToScreen(3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    AppTheme theme,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: theme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: theme.text.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaregiverPortal(AppTheme theme) {
    return GestureDetector(
      onTap: () {
        // Navigate to Caregiver Portal (index 4 in drawer)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CaregiverScreen(),
          ),
        );
        print('Caregiver Portal tapped');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(Icons.people_outline, color: theme.primary, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Caregiver Portal',
              style: TextStyle(
                color: theme.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with your support network',
              style: TextStyle(
                color: theme.text.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Tap to Access',
                style: TextStyle(
                  color: theme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(AppTheme theme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.purple,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(child: Text('😱', style: const TextStyle(fontSize: 24))),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.priority_high,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(int index) {
    // Use the callback to communicate with MainLayout
    widget.onNavigateToScreen(index);
    print('Navigate to screen: $index');
  }
}
