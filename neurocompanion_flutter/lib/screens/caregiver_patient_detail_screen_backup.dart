import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/caregiver_service.dart';
import 'package:neurocompanion_flutter/services/api_client.dart';

class CaregiverPatientDetailScreen extends StatefulWidget {
  final String patientId;

  const CaregiverPatientDetailScreen({
    super.key,
    required this.patientId,
  });

  @override
  State<CaregiverPatientDetailScreen> createState() => _CaregiverPatientDetailScreenState();
}

class _CaregiverPatientDetailScreenState extends State<CaregiverPatientDetailScreen> {
  late CaregiverService _caregiverService;
  Map<String, dynamic>? _patientDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _caregiverService = CaregiverService(apiClient: context.read<ApiClient>());
    _loadPatientDetail();
  }

  Future<void> _loadPatientDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await _caregiverService.getPatientDetail(widget.patientId);
      if (mounted) {
        setState(() {
          _patientDetail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load patient details';
          _isLoading = false;
        });
      }
    }
  }

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
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.text),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Patient Details',
              style: TextStyle(color: theme.text),
            ),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(_error!, style: TextStyle(color: theme.text)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadPatientDetail,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Patient Info Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.border),
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: theme.primary,
                                  child: Text(
                                    _patientDetail?['patient']?['name']?.toString()[0].toUpperCase() ?? 'P',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _patientDetail?['patient']?['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: theme.text,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _patientDetail?['patient']?['email'] ?? '',
                                  style: TextStyle(
                                    color: theme.text.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                if (_patientDetail?['patient']?['neurotype'] != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: theme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _patientDetail!['patient']['neurotype'],
                                      style: TextStyle(
                                        color: theme.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Recent Journal Entries
                          if (_patientDetail?['recentJournals'] != null) ...[
                            Text(
                              'Recent Journal Entries',
                              style: TextStyle(
                                color: theme.text,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (var journal in _patientDetail!['recentJournals'] as List)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
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
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          journal['emotion'] ?? 'neutral',
                                          style: TextStyle(
                                            color: theme.primary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          journal['createdAt']?.toString().substring(0, 10) ?? '',
                                          style: TextStyle(
                                            color: theme.text.withOpacity(0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      journal['content'] ?? '',
                                      style: TextStyle(
                                        color: theme.text,
                                        fontSize: 14,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                          ],

                          // Mood Summary
                          if (_patientDetail?['moodSummary'] != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Mood Summary',
                              style: TextStyle(
                                color: theme.text,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.border),
                              ),
                              child: Column(
                                children: [
                                  _buildMoodStat(
                                    theme,
                                    'Average Mood',
                                    _patientDetail!['moodSummary']['avgMood']?.toStringAsFixed(1) ?? 'N/A',
                                    Icons.sentiment_satisfied_alt,
                                  ),
                                  const Divider(),
                                  _buildMoodStat(
                                    theme,
                                    'Most Frequent',
                                    _patientDetail!['moodSummary']['mostFrequent'] ?? 'N/A',
                                    Icons.psychology,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildMoodStat(AppTheme theme, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: theme.text.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.text,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
