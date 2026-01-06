import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/caregiver_service.dart';
import 'package:neurocompanion_flutter/services/api_client.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

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
  Map<String, dynamic>? _processedData;
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _error;
  String _selectedTimeframe = 'week';

  @override
  void initState() {
    super.initState();
    _caregiverService = CaregiverService(apiClient: context.read<ApiClient>());
    _loadPatientDetail();
  }

  Future<void> _downloadReport() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final patient = _patientDetail?['patient'] as Map<String, dynamic>?;
      final patientName = (patient?['name'] as String? ?? 'Patient').replaceAll(' ', '-');
      
      // 1. Download bytes
      final bytes = await _caregiverService.downloadPatientReport(widget.patientId);

      // 2. Get save directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Report-$patientName-${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');

      // 3. Write file
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report downloaded successfully'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () {
                OpenFilex.open(file.path);
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
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
          _processedData = _processPatientData(detail);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading patient detail: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load patient details';
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _processPatientData(Map<String, dynamic> detail) {
    final data = detail['data'] as Map<String, dynamic>? ?? {};
    final emotions = (data['emotions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final tasks = (data['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final journals = (data['journals'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return {
      'emotionTrendData': _calculateEmotionTrend(emotions),
      'taskCompletionData': _calculateTaskCompletion(tasks),
      'emotionDistribution': _calculateEmotionDistribution(emotions),
      'careReports': _generateCareReports(journals, emotions, tasks),
      'aiRecommendations': _generateAIRecommendations(detail, emotions, tasks, journals),
      'averageMood': _calculateAverageMood(emotions),
      'taskCompletionRate': _calculateTaskCompletionRate(tasks),
    };
  }

  List<Map<String, dynamic>> _calculateEmotionTrend(List<Map<String, dynamic>> emotions) {
    final List<Map<String, dynamic>> trendData = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayEmotions = emotions.where((e) {
        final emotionDate = DateTime.tryParse(e['timestamp'] as String? ?? e['createdAt'] as String? ?? '');
        return emotionDate != null && DateFormat('yyyy-MM-dd').format(emotionDate) == dateStr;
      }).toList();

      double mood = 5.0;
      double stress = 5.0;
      double energy = 5.0;

      if (dayEmotions.isNotEmpty) {
        final positiveEmotions = ['happy', 'excited', 'grateful', 'peaceful', 'content', 'calm'];
        final negativeEmotions = ['sad', 'anxious', 'angry', 'frustrated', 'stressed', 'worried'];

        final positiveCount = dayEmotions.where((e) => 
          positiveEmotions.contains((e['emotion'] as String? ?? '').toLowerCase())
        ).length;
        final negativeCount = dayEmotions.where((e) => 
          negativeEmotions.contains((e['emotion'] as String? ?? '').toLowerCase())
        ).length;

        final avgIntensity = dayEmotions.fold<double>(0.0, (sum, e) => 
          sum + ((e['intensity'] as num?)?.toDouble() ?? 5.0)
        ) / dayEmotions.length;

        mood = (avgIntensity + (positiveCount > 0 ? 1 : 0) - (negativeCount > 0 ? 1 : 0)).clamp(1.0, 10.0);
        stress = negativeCount > 0 ? (7.0 + (negativeCount / dayEmotions.length)).clamp(1.0, 10.0) : 2.0;
        energy = avgIntensity.clamp(1.0, 10.0);
      }

      trendData.add({
        'day': DateFormat('EEE').format(date),
        'date': dateStr,
        'mood': mood,
        'stress': stress,
        'energy': energy,
      });
    }

    return trendData;
  }

  List<Map<String, dynamic>> _calculateTaskCompletion(List<Map<String, dynamic>> tasks) {
    final List<Map<String, dynamic>> completionData = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayTasks = tasks.where((t) {
        final taskDate = DateTime.tryParse(t['createdAt'] as String? ?? '');
        return taskDate != null && DateFormat('yyyy-MM-dd').format(taskDate) == dateStr;
      }).toList();

      final completed = dayTasks.where((t) => t['status'] == 'done' || t['status'] == 'completed').length;

      completionData.add({
        'day': DateFormat('EEE').format(date),
        'completed': completed,
        'total': dayTasks.length,
      });
    }

    return completionData;
  }

  List<Map<String, dynamic>> _calculateEmotionDistribution(List<Map<String, dynamic>> emotions) {
    final Map<String, int> emotionCounts = {};
    
    for (var emotion in emotions) {
      final emotionName = (emotion['emotion'] as String? ?? 'neutral').toLowerCase();
      emotionCounts[emotionName] = (emotionCounts[emotionName] ?? 0) + 1;
    }

    final categories = {
      'Happy': {'emotions': ['happy', 'excited', 'grateful'], 'color': Colors.green},
      'Calm': {'emotions': ['calm', 'peaceful', 'content'], 'color': Colors.blue},
      'Neutral': {'emotions': ['neutral'], 'color': Colors.grey},
      'Stressed': {'emotions': ['stressed', 'frustrated', 'worried'], 'color': Colors.orange},
      'Confused': {'emotions': ['confused', 'surprised'], 'color': Colors.purple},
      'Sad': {'emotions': ['sad', 'anxious', 'angry'], 'color': Colors.red},
    };

    final distribution = <Map<String, dynamic>>[];
    int total = emotions.length;

    categories.forEach((category, data) {
      final categoryEmotions = data['emotions'] as List<String>;
      final count = categoryEmotions.fold<int>(0, (sum, emotion) => sum + (emotionCounts[emotion] ?? 0));
      if (count > 0) {
        distribution.add({
          'name': category,
          'value': ((count / total) * 100).round(),
          'color': data['color'],
        });
      }
    });

    return distribution;
  }

  List<Map<String, dynamic>> _generateCareReports(
    List<Map<String, dynamic>> journals,
    List<Map<String, dynamic>> emotions,
    List<Map<String, dynamic>> tasks,
  ) {
    final reports = <Map<String, dynamic>>[];

    for (int i = 0; i < math.min(3, journals.length); i++) {
      final journal = journals[i];
      final journalDate = DateTime.tryParse(journal['createdAt'] as String? ?? '');
      
      if (journalDate != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(journalDate);
        final dayEmotions = emotions.where((e) {
          final emotionDate = DateTime.tryParse(e['timestamp'] as String? ?? '');
          return emotionDate != null && DateFormat('yyyy-MM-dd').format(emotionDate) == dateStr;
        }).toList();

        final dayTasks = tasks.where((t) {
          final taskDate = DateTime.tryParse(t['createdAt'] as String? ?? '');
          return taskDate != null && DateFormat('yyyy-MM-dd').format(taskDate) == dateStr;
        }).toList();

        final completed = dayTasks.where((t) => t['status'] == 'done' || t['status'] == 'completed').length;
        final mood = dayEmotions.isNotEmpty ? dayEmotions.first['emotion'] as String? ?? 'neutral' : 'neutral';

        final recommendations = <String>[];
        if (mood == 'stressed' || mood == 'anxious') {
          recommendations.add('Consider relaxation exercises');
        }
        if (completed < dayTasks.length / 2) {
          recommendations.add('Break tasks into smaller steps');
        }
        if (dayEmotions.isEmpty) {
          recommendations.add('Encourage daily mood tracking');
        }

        reports.add({
          'id': 'report_$i',
          'date': journalDate.toIso8601String(),
          'mood': mood,
          'tasksCompleted': '$completed/${dayTasks.length}',
          'notes': journal['content'] as String? ?? 'No notes available',
          'recommendations': recommendations,
        });
      }
    }

    return reports;
  }

  List<String> _generateAIRecommendations(
    Map<String, dynamic> detail,
    List<Map<String, dynamic>> emotions,
    List<Map<String, dynamic>> tasks,
    List<Map<String, dynamic>> journals,
  ) {
    final recommendations = <String>[];
    final summary = detail['summary'] as Map<String, dynamic>? ?? {};

    // Mood trend recommendation
    final moodTrend = summary['moodTrend'] as String? ?? 'stable';
    if (moodTrend == 'declining') {
      recommendations.add('🔍 Monitor closely: Mood trend is declining. Consider scheduling a check-in session.');
    } else if (moodTrend == 'improving') {
      recommendations.add('✨ Positive progress: Continue current support strategies as mood is improving.');
    }

    // Task completion recommendation
    final completedTasks = summary['completedTasks'] as int? ?? 0;
    final totalTasks = summary['totalTasks'] as int? ?? 1;
    final taskRate = (completedTasks / totalTasks * 100).round();
    
    if (taskRate < 50) {
      recommendations.add('📋 Task support needed: Low completion rate ($taskRate%). Help break tasks into manageable steps.');
    } else if (taskRate > 80) {
      recommendations.add('🎯 Excellent task management: High completion rate ($taskRate%). Consider increasing challenge level.');
    }

    // Journal activity recommendation
    final journalCount = summary['totalJournals'] as int? ?? 0;
    if (journalCount < 3) {
      recommendations.add('📝 Encourage journaling: Low journal activity. Promote daily reflection for better insights.');
    } else if (journalCount > 10) {
      recommendations.add('💭 Active reflection: Strong journaling habit. Use insights for personalized care.');
    }

    // Emotion diversity recommendation
    final recentEmotions = emotions.take(10).map((e) => e['emotion'] as String? ?? '').toSet();
    if (recentEmotions.length < 3) {
      recommendations.add('🎨 Limited emotional range: Consider activities to explore different emotions.');
    }

    // Wellness score recommendation
    final wellnessScore = summary['wellnessScore'] as int? ?? 50;
    if (wellnessScore < 40) {
      recommendations.add('⚠️ Low wellness score: Immediate attention needed. Schedule comprehensive review.');
    } else if (wellnessScore > 80) {
      recommendations.add('🌟 Strong wellness: Maintain current routines and celebrate progress.');
    }

    return recommendations.take(4).toList();
  }

  double _calculateAverageMood(List<Map<String, dynamic>> emotions) {
    if (emotions.isEmpty) return 5.0;
    
    final moodScores = emotions.map((e) {
      final emotion = (e['emotion'] as String? ?? '').toLowerCase();
      final positiveEmotions = ['happy', 'excited', 'grateful', 'peaceful', 'content', 'calm'];
      final negativeEmotions = ['sad', 'anxious', 'angry', 'frustrated', 'stressed', 'worried'];
      
      if (positiveEmotions.contains(emotion)) return 8.0;
      if (negativeEmotions.contains(emotion)) return 3.0;
      return 5.0;
    }).toList();

    return moodScores.reduce((a, b) => a + b) / moodScores.length;
  }

  int _calculateTaskCompletionRate(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) return 0;
    final completed = tasks.where((t) => t['status'] == 'done' || t['status'] == 'completed').length;
    return ((completed / tasks.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return Scaffold(
          backgroundColor: theme.background,
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : _error != null
                  ? _buildErrorState(theme)
                  : _buildPatientDetail(theme),
        );
      },
    );
  }

  Widget _buildErrorState(AppTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(color: theme.text, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadPatientDetail,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Patients'),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetail(AppTheme theme) {
    final patient = _patientDetail?['patient'] as Map<String, dynamic>?;
    final summary = _patientDetail?['summary'] as Map<String, dynamic>?;
    final data = _patientDetail?['data'] as Map<String, dynamic>?;
    
    if (patient == null || _processedData == null) {
      return Center(child: Text('Patient data not available', style: TextStyle(color: theme.text)));
    }

    final recentEmotions = ((data?['emotions'] as List?)?.take(7).cast<Map<String, dynamic>>() ?? []).toList();

    return CustomScrollView(
      slivers: [
        // Custom App Bar with Back Button
        SliverAppBar(
          backgroundColor: theme.card,
          elevation: 0,
          pinned: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.text),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Patient Details',
            style: TextStyle(color: theme.text, fontWeight: FontWeight.bold),
          ),
          actions: [
            // Download Report Button
            if (!_isLoading && _error == null)
              _isDownloading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.download_rounded, color: theme.primary),
                    tooltip: 'Download PDF Report',
                    onPressed: _downloadReport,
                  ),
            // Timeframe Selector
            _buildTimeframeChips(theme),
            const SizedBox(width: 8),
          ],
        ),
        
        // Patient Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Patient Header Card
              _buildPatientHeader(theme, patient),
              const SizedBox(height: 16),

              // Metrics Cards Row
              _buildMetricsRow(theme, summary),
              const SizedBox(height: 16),

              // Charts Section
              _buildChartsSection(theme),
              const SizedBox(height: 16),

              // Emotion Distribution
              if ((_processedData!['emotionDistribution'] as List).isNotEmpty)
                _buildEmotionDistribution(theme),
              const SizedBox(height: 16),

              // Recent Emotions
              if (recentEmotions.isNotEmpty)
                _buildRecentEmotions(theme, recentEmotions),
              const SizedBox(height: 16),

              // Care Reports
              if ((_processedData!['careReports'] as List).isNotEmpty)
                _buildCareReports(theme),
              const SizedBox(height: 16),

              // AI Recommendations
              if ((_processedData!['aiRecommendations'] as List).isNotEmpty)
                _buildAIRecommendations(theme),
              
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeframeChips(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['week', 'month', 'quarter'].map((timeframe) {
          final isSelected = _selectedTimeframe == timeframe;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: () => setState(() => _selectedTimeframe = timeframe),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primary : theme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? theme.primary : theme.border),
                ),
                child: Text(
                  timeframe[0].toUpperCase() + timeframe.substring(1),
                  style: TextStyle(
                    color: isSelected ? Colors.white : theme.text,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPatientHeader(AppTheme theme, Map<String, dynamic> patient) {
    final name = patient['name'] as String? ?? 'Unknown';
    final email = patient['email'] as String? ?? '';
    final neurotype = patient['neurotype'] as String?;
    final createdAt = patient['createdAt'] as String?;
    final lastActive = _patientDetail?['data']?['emotions']?[0]?['timestamp'] as String? ?? createdAt;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primary, theme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Patient Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: theme.text.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                if (neurotype != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      neurotype,
                      style: TextStyle(
                        color: theme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: theme.text.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      'Last active: ${_formatDate(lastActive)}',
                      style: TextStyle(
                        color: theme.text.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(AppTheme theme, Map<String, dynamic>? summary) {
    final wellnessScore = summary?['wellnessScore'] as int? ?? 0;
    final totalTasks = summary?['totalTasks'] as int? ?? 0;
    final completedTasks = summary?['completedTasks'] as int? ?? 0;
    final totalJournals = summary?['totalJournals'] as int? ?? 0;
    final averageMood = _processedData?['averageMood'] as double? ?? 5.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                'Wellness Score',
                '$wellnessScore/100',
                Icons.favorite,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                theme,
                'Avg Mood',
                '${averageMood.toStringAsFixed(1)}/10',
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
              child: _buildMetricCard(
                theme,
                'Tasks',
                '$completedTasks/$totalTasks',
                Icons.check_circle,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                theme,
                'Journals',
                '$totalJournals',
                Icons.book,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(AppTheme theme, String label, String value, IconData icon, Color iconColor) {
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
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
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
            label,
            style: TextStyle(
              color: theme.text.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(AppTheme theme) {
    final emotionTrendData = _processedData!['emotionTrendData'] as List<Map<String, dynamic>>;
    final taskCompletionData = _processedData!['taskCompletionData'] as List<Map<String, dynamic>>;

    return Column(
      children: [
        // Emotion Trend Chart
        Container(
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
                  Icon(Icons.show_chart, color: theme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Emotion Trend (7 Days)',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(color: theme.text.withOpacity(0.6), fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < emotionTrendData.length) {
                              return Text(
                                emotionTrendData[value.toInt()]['day'],
                                style: TextStyle(color: theme.text.withOpacity(0.6), fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minY: 0,
                    maxY: 10,
                    lineBarsData: [
                      // Mood line
                      LineChartBarData(
                        spots: emotionTrendData.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), (e.value['mood'] as num).toDouble());
                        }).toList(),
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      ),
                      // Stress line
                      LineChartBarData(
                        spots: emotionTrendData.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), (e.value['stress'] as num).toDouble());
                        }).toList(),
                        isCurved: true,
                        color: Colors.orange,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      ),
                      // Energy line
                      LineChartBarData(
                        spots: emotionTrendData.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), (e.value['energy'] as num).toDouble());
                        }).toList(),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem('Mood', Colors.green),
                  _buildLegendItem('Stress', Colors.orange),
                  _buildLegendItem('Energy', Colors.blue),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Task Completion Chart
        Container(
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
                  Icon(Icons.check_circle, color: theme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Task Completion (7 Days)',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(color: theme.text.withOpacity(0.6), fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < taskCompletionData.length) {
                              return Text(
                                taskCompletionData[value.toInt()]['day'],
                                style: TextStyle(color: theme.text.withOpacity(0.6), fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: taskCompletionData.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: (e.value['completed'] as num).toDouble(),
                            color: theme.primary,
                            width: 20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildEmotionDistribution(AppTheme theme) {
    final distribution = _processedData!['emotionDistribution'] as List<Map<String, dynamic>>;

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
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: distribution.map((item) {
                  return PieChartSectionData(
                    value: (item['value'] as num).toDouble(),
                    title: '${item['value']}%',
                    color: item['color'] as Color,
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: distribution.map((item) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item['name']}: ${item['value']}%',
                    style: TextStyle(fontSize: 12, color: theme.text),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEmotions(AppTheme theme, List<Map<String, dynamic>> emotions) {
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
              Icon(Icons.favorite, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recent Emotions',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: emotions.map((emotion) {
              final emotionName = emotion['emotion'] as String? ?? 'neutral';
              final emoji = _getEmotionEmoji(emotionName);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      emotionName,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCareReports(AppTheme theme) {
    final reports = _processedData!['careReports'] as List<Map<String, dynamic>>;

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
              Icon(Icons.assignment, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Care Reports',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...reports.map((report) => _buildCareReportItem(theme, report)),
        ],
      ),
    );
  }

  Widget _buildCareReportItem(AppTheme theme, Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(report['date']),
                style: TextStyle(
                  color: theme.text.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Mood: ${report['mood']}',
                    style: TextStyle(
                      color: theme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tasks: ${report['tasksCompleted']}',
                    style: TextStyle(
                      color: theme.text.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report['notes'],
            style: TextStyle(
              color: theme.text,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if ((report['recommendations'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (report['recommendations'] as List).map((rec) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rec,
                    style: TextStyle(
                      color: theme.primary,
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIRecommendations(AppTheme theme) {
    final recommendations = _processedData!['aiRecommendations'] as List<String>;

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
              Icon(Icons.psychology, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Recommendations',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((rec) => _buildRecommendationItem(theme, rec)),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(AppTheme theme, String recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(
                color: theme.text,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d, y').format(date);
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getEmotionEmoji(String emotion) {
    const emotionEmojiMap = {
      'happy': '😊',
      'sad': '😔',
      'calm': '😌',
      'stressed': '😟',
      'angry': '😠',
      'neutral': '😐',
      'excited': '🤩',
      'worried': '😥',
      'confused': '🤔',
      'surprised': '😲',
      'anxious': '😰',
      'frustrated': '😤',
      'grateful': '🙏',
      'peaceful': '☮️',
      'content': '😊',
    };
    return emotionEmojiMap[emotion.toLowerCase()] ?? '😊';
  }
}
