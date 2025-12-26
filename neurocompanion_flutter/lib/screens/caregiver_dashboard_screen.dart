import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/caregiver_service.dart';
import 'package:neurocompanion_flutter/services/api_client.dart';
import 'package:neurocompanion_flutter/models/caregiver_models.dart';
import 'package:neurocompanion_flutter/screens/caregiver_patient_list_screen.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  final bool showNavigationBar;

  const CaregiverDashboardScreen({
    super.key,
    this.showNavigationBar = true,
  });

  @override
  State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  late CaregiverService _caregiverService;
  List<CaregiverPatient> _patients = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _caregiverService = CaregiverService(apiClient: context.read<ApiClient>());
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final patientsData = await _caregiverService.getPatients();
      if (mounted) {
        setState(() {
          _patients = patientsData.map((p) => CaregiverPatient.fromJson(p)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load patients';
          _isLoading = false;
        });
      }
    }
  }

  int _calculateAverageWellness() {
    if (_patients.isEmpty) return 0;
    final total = _patients.fold<double>(
      0,
      (sum, p) => sum + (p.moodScore ?? 0),
    );
    return (total / _patients.length).round();
  }

  int _calculateTotalTasks() {
    // For now, return 0 until we fetch detailed stats
    return 0;
  }

  int _calculateCompletedTasks() {
    // For now, return 0 until we fetch detailed stats
    return 0;
  }

  int _calculateCompletionRate() {
    final total = _calculateTotalTasks();
    if (total == 0) return 0;
    final completed = _calculateCompletedTasks();
    return ((completed / total) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        if (_isLoading) {
          return Scaffold(
            backgroundColor: theme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading dashboard...',
                    style: TextStyle(color: theme.text, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadPatients,
              color: theme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Overview',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your patients\' progress at a glance',
                      style: TextStyle(
                        color: theme.text.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error message
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: theme.text),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Quick Stats
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildStatCard(
                          theme,
                          Icons.people,
                          'Total Patients',
                          '${_patients.length}',
                          '',
                          Colors.blue,
                        ),
                        _buildStatCard(
                          theme,
                          Icons.favorite,
                          'Avg Wellness',
                          '${_calculateAverageWellness()}%',
                          '',
                          Colors.red,
                        ),
                        _buildStatCard(
                          theme,
                          Icons.check_circle,
                          'Total Tasks',
                          '${_calculateTotalTasks()}',
                          '${_calculateCompletedTasks()} completed',
                          Colors.green,
                        ),
                        _buildStatCard(
                          theme,
                          Icons.bar_chart,
                          'Completion Rate',
                          '${_calculateCompletionRate()}%',
                          '',
                          Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Welcome Card
                    // Container(
                    //   width: double.infinity,
                    //   padding: const EdgeInsets.all(24),
                    //   decoration: BoxDecoration(
                    //     gradient: LinearGradient(
                    //       colors: [
                    //         theme.primary.withOpacity(0.05),
                    //         theme.secondary.withOpacity(0.03),
                    //       ],
                    //       begin: Alignment.topLeft,
                    //       end: Alignment.bottomRight,
                    //     ),
                    //     borderRadius: BorderRadius.circular(16),
                    //     border: Border.all(
                    //       color: theme.border.withOpacity(0.5),
                    //       style: BorderStyle.solid,
                    //       width: 1,
                    //     ),
                    //   ),
                    //   child: Column(
                    //     children: [
                    //       Text(
                    //         'Welcome to your dashboard',
                    //         style: TextStyle(
                    //           color: theme.text,
                    //           fontSize: 18,
                    //           fontWeight: FontWeight.w600,
                    //         ),
                    //       ),
                    //       const SizedBox(height: 8),
                    //       Text(
                    //         'Use the navigation bar to manage your patients and view detailed reports.',
                    //         style: TextStyle(
                    //           color: theme.text.withOpacity(0.7),
                    //           fontSize: 14,
                    //         ),
                    //         textAlign: TextAlign.center,
                    //       ),
                    //       const SizedBox(height: 16),
                    //       ElevatedButton.icon(
                    //         onPressed: () {
                    //           Navigator.push(
                    //             context,
                    //             MaterialPageRoute(
                    //               builder: (_) => const CaregiverPatientListScreen(),
                    //             ),
                    //           );
                    //         },
                    //         style: ElevatedButton.styleFrom(
                    //           backgroundColor: theme.primary,
                    //           padding: const EdgeInsets.symmetric(
                    //             horizontal: 24,
                    //             vertical: 12,
                    //           ),
                    //           shape: RoundedRectangleBorder(
                    //             borderRadius: BorderRadius.circular(12),
                    //           ),
                    //         ),
                    //         icon: const Icon(Icons.people, color: Colors.white),
                    //         label: const Text(
                    //           'View Patients',
                    //           style: TextStyle(
                    //             color: Colors.white,
                    //             fontWeight: FontWeight.w600,
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    AppTheme theme,
    IconData icon,
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: theme.text.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
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
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: TextStyle(
                color: theme.text.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}
