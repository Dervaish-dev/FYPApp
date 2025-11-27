import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';

class CaregiverScreen extends StatelessWidget {
  const CaregiverScreen({super.key});

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
                    'Caregiver Portal',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect with your support network',
                    style: TextStyle(
                      color: theme.text.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Caregiver Status
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
                        Row(
                          children: [
                            Icon(Icons.people, color: theme.primary, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Your Caregivers',
                              style: TextStyle(
                                color: theme.text,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildCaregiverCard(theme, 'Dr. Sarah Johnson', 'Psychiatrist', Icons.medical_services),
                        const SizedBox(height: 12),
                        _buildCaregiverCard(theme, 'Mom', 'Family Support', Icons.family_restroom),
                        const SizedBox(height: 12),
                        _buildCaregiverCard(theme, 'Alex (Friend)', 'Peer Support', Icons.person),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Reports
                  Text(
                    'Recent Reports',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildReportCard(theme, 'Weekly Summary', 'Dec 15, 2024', 'Good progress this week'),
                  const SizedBox(height: 12),
                  _buildReportCard(theme, 'Mood Analysis', 'Dec 14, 2024', 'Stable mood patterns'),
                  const SizedBox(height: 12),
                  _buildReportCard(theme, 'Task Completion', 'Dec 13, 2024', 'Completed 8/10 tasks'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCaregiverCard(AppTheme theme, String name, String role, IconData icon) {
    return Container(
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
            child: Icon(icon, color: theme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  role,
                  style: TextStyle(
                    color: theme.text.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Active',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(AppTheme theme, String title, String date, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  color: theme.text.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: theme.text.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
