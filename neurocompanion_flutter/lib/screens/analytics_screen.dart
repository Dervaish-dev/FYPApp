import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/bloc/blocs.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/services/analytics_service.dart';
import 'package:neurocompanion_flutter/widgets/mood_chart_widget.dart';
import 'package:neurocompanion_flutter/widgets/emotion_pie_chart_widget.dart';
import 'package:neurocompanion_flutter/screens/breathing_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  AnalyticsData? _analyticsData;
  bool _isLoading = true;
  String _selectedPeriod = '30';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _analyticsService.getJournalAnalytics(
        authState.user.id,
        days: int.parse(_selectedPeriod),
      );
      
      if (mounted) {
        setState(() {
          _analyticsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load analytics';
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
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadAnalytics,
              color: theme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analytics',
                                style: TextStyle(
                                  color: theme.text,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track your mental health progress',
                                style: TextStyle(
                                  color: theme.text.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Period Selector
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.border),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedPeriod,
                            underline: Container(),
                            dropdownColor: theme.card,
                            style: TextStyle(color: theme.text, fontSize: 14),
                            icon: Icon(Icons.arrow_drop_down, color: theme.text),
                            items: const [
                              DropdownMenuItem(value: '7', child: Text('7 Days')),
                              DropdownMenuItem(value: '30', child: Text('30 Days')),
                              DropdownMenuItem(value: '90', child: Text('90 Days')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedPeriod = value);
                                _loadAnalytics();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Loading or Error State
                    if (_isLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: CircularProgressIndicator(color: theme.primary),
                        ),
                      )
                    else if (_error != null)
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error!, style: TextStyle(color: theme.text)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadAnalytics,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (_analyticsData != null) ...[
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              theme,
                              'Total Entries',
                              _analyticsData!.summary.totalEntries.toString(),
                              Icons.book,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              theme,
                              'Avg Mood',
                              _analyticsData!.summary.avgMood.toStringAsFixed(1),
                              Icons.sentiment_satisfied_alt,
                              Colors.green,
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
                              'Emotions',
                              _analyticsData!.summary.totalEmotions.toString(),
                              Icons.psychology,
                              Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              theme,
                              'Period',
                              _analyticsData!.summary.period,
                              Icons.calendar_today,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Breathing Exercises Link
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BreathingScreen()),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.withOpacity(0.8), Colors.cyan.withOpacity(0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.air, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Breathing Exercises',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Practice mindfulness with guided breathing',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                            Row(
                              children: [
                                Icon(Icons.show_chart, color: theme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Mood Trends',
                                  style: TextStyle(
                                    color: theme.text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your mood patterns over time',
                              style: TextStyle(
                                color: theme.text.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            MoodChartWidget(
                              moodData: _analyticsData!.moodTrends,
                              theme: theme,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Emotion Distribution
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
                                Icon(Icons.pie_chart, color: theme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Emotion Distribution',
                                  style: TextStyle(
                                    color: theme.text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Breakdown of your emotions',
                              style: TextStyle(
                                color: theme.text.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            EmotionPieChartWidget(
                              emotionStats: _analyticsData!.emotionDistribution,
                              theme: theme,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Insights Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primary.withOpacity(0.1),
                              theme.secondary.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb, color: theme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Key Insights',
                                  style: TextStyle(
                                    color: theme.text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInsightRow(
                              theme,
                              Icons.trending_up,
                              _getMoodTrendInsight(),
                            ),
                            const SizedBox(height: 12),
                            _buildInsightRow(
                              theme,
                              Icons.star,
                              _getMostFrequentEmotion(),
                            ),
                            const SizedBox(height: 12),
                            _buildInsightRow(
                              theme,
                              Icons.tips_and_updates,
                              _getRecommendation(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
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
              fontSize: 20,
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

  Widget _buildInsightRow(AppTheme theme, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: theme.text,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  String _getMoodTrendInsight() {
    if (_analyticsData == null || _analyticsData!.moodTrends.isEmpty) {
      return 'Start journaling to track your mood trends';
    }
    
    final avgMood = _analyticsData!.summary.avgMood;
    if (avgMood >= 7) {
      return 'Your mood has been consistently positive! Keep up the great work.';
    } else if (avgMood >= 5) {
      return 'Your mood is balanced. Consider activities that boost your wellbeing.';
    } else {
      return 'Your mood could use some attention. Reach out for support if needed.';
    }
  }

  String _getMostFrequentEmotion() {
    if (_analyticsData == null || _analyticsData!.emotionDistribution.isEmpty) {
      return 'No emotion data available yet';
    }
    
    final sorted = List<EmotionStat>.from(_analyticsData!.emotionDistribution)
      ..sort((a, b) => b.count.compareTo(a.count));
    
    final top = sorted.first;
    return 'Your most frequent emotion is "${top.emotion}" (${top.count} entries)';
  }

  String _getRecommendation() {
    if (_analyticsData == null) {
      return 'Continue journaling regularly to receive personalized insights';
    }
    
    final totalEntries = _analyticsData!.summary.totalEntries;
    final daysInPeriod = int.parse(_selectedPeriod);
    final avgEntriesPerDay = totalEntries / daysInPeriod;
    
    if (avgEntriesPerDay < 0.5) {
      return 'Try journaling more frequently for better insights into your mental health';
    } else if (avgEntriesPerDay >= 1) {
      return 'Excellent journaling consistency! Your insights will be more accurate.';
    } else {
      return 'Good progress! Aim for daily journaling to maximize benefits.';
    }
  }
}