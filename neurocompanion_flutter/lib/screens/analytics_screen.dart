import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

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
                  // Header
                  Text(
                    'Analytics',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your mental health progress',
                    style: TextStyle(
                      color: theme.text.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mood Trends Chart
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mood Trends (Last 7 Days)',
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: theme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.border),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.show_chart,
                                  size: 48,
                                  color: theme.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Chart Coming Soon',
                                  style: TextStyle(
                                    color: theme.text.withOpacity(0.7),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Statistics Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Happy Days',
                          '5',
                          Icons.sentiment_very_satisfied,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Tasks Done',
                          '12',
                          Icons.check_circle,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Journal Entries',
                          '8',
                          Icons.book,
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Streak',
                          '7 days',
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(AppTheme theme, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: theme.text,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: theme.text.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}