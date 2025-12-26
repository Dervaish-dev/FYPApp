import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/bloc/blocs.dart';
import 'package:neurocompanion_flutter/screens/caregiver_screen.dart';
import 'package:neurocompanion_flutter/screens/breathing_screen.dart';
import 'package:neurocompanion_flutter/services/api_client.dart';
import 'package:neurocompanion_flutter/services/api_config.dart';
import 'package:neurocompanion_flutter/services/token_store.dart';
import 'package:neurocompanion_flutter/services/services.dart';
import 'package:neurocompanion_flutter/models/models.dart';
import 'package:neurocompanion_flutter/models/task.dart';

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
  bool _isLoading = true;
  Map<String, dynamic> _metrics = {
    'moodStability': 85,
    'taskCompletion': 72,
    'breathingExercisesToday': 0,
    'moodMessage': 'Start logging your emotions to track your mood stability!',
    'taskMessage': 'Create tasks to track your progress and stay organized!',
    'hasEmotionData': false,
    'hasTaskData': false,
  };

  @override
  void initState() {
    super.initState();
    // Load data when dashboard opens
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    // Trigger BLoC events to load data
    context.read<TaskBloc>().add(LoadTasks());
    context.read<EmotionBloc>().add(LoadEmotions());
    context.read<JournalBloc>().add(LoadJournalEntries());
    context.read<AnalyticsBloc>().add(LoadAnalytics());
    
    // Wait a bit for BLoC events to complete
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Load breathing exercises and calculate metrics
    await _calculateMetrics();
    
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _calculateMetrics() async {
    try {
      print('📊 [DASHBOARD] Starting metrics calculation...');
      
      final apiClient = ApiClient(
        baseUrl: ApiConfig.baseUrl,
        tokenStore: SharedPrefsTokenStore(),
      );
      
      // Get current user ID
      final authService = AuthService();
      final user = authService.currentUser ?? await authService.getCurrentUser();
      final userId = user?.id;
      
      print('📊 [DASHBOARD] User ID: $userId');
      
      if (userId == null) {
        print('⚠️ [DASHBOARD] No user ID found, skipping metrics calculation');
        return;
      }
      
      // Get emotion history
      final emotionState = context.read<EmotionBloc>().state;
      print('📊 [DASHBOARD] Emotion state type: ${emotionState.runtimeType}');
      
      List emotions = [];
      if (emotionState is EmotionLoaded) {
        emotions = emotionState.emotions;
        print('📊 [DASHBOARD] Emotions loaded: ${emotions.length} items');
        if (emotions.isNotEmpty) {
          print('📊 [DASHBOARD] First emotion type: ${emotions.first.runtimeType}');
          if (emotions.first is Emotion) {
            final e = emotions.first as Emotion;
            print('📊 [DASHBOARD] First emotion data: emotion=${e.emotion}, intensity=${e.intensity}');
          } else {
            print('⚠️ [DASHBOARD] First emotion is NOT Emotion type, it\'s a ${emotions.first.runtimeType}');
          }
        }
      } else {
        print('📊 [DASHBOARD] Emotion state is NOT EmotionLoaded');
      }
      
      // Get tasks
      final taskState = context.read<TaskBloc>().state;
      print('📊 [DASHBOARD] Task state type: ${taskState.runtimeType}');
      
      List tasks = [];
      if (taskState is TaskLoaded) {
        tasks = taskState.tasks;
        print('📊 [DASHBOARD] Tasks loaded: ${tasks.length} items');
        if (tasks.isNotEmpty) {
          print('📊 [DASHBOARD] First task type: ${tasks.first.runtimeType}');
          if (tasks.first is Task) {
            final t = tasks.first as Task;
            print('📊 [DASHBOARD] First task data: title=${t.title}, status=${t.status}');
          } else {
            print('⚠️ [DASHBOARD] First task is NOT Task type, it\'s a ${tasks.first.runtimeType}');
          }
        }
      } else {
        print('📊 [DASHBOARD] Task state is NOT TaskLoaded');
      }
      
      // Get breathing exercises for today
      try {
        print('📊 [DASHBOARD] Fetching breathing exercises for user: $userId');
        final breathingResponse = await apiClient.get('/wellness/breathing/$userId');
        print('📊 [DASHBOARD] Breathing response type: ${breathingResponse.runtimeType}');
        print('📊 [DASHBOARD] Breathing response keys: ${breathingResponse.keys}');
        print('📊 [DASHBOARD] Breathing response: $breathingResponse');
        
        // The response has a 'data' object with 'history' inside
        final data = breathingResponse['data'] as Map? ?? {};
        final history = data['history'] as List? ?? [];
        print('📊 [DASHBOARD] Breathing history count: ${history.length}');
        
        if (history.isNotEmpty) {
          print('📊 [DASHBOARD] First breathing entry: ${history.first}');
        }
        
        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        print('📊 [DASHBOARD] Today\'s date string: $todayStr');
        
        int breathingToday = 0;
        for (var e in history) {
          final createdAt = e['createdAt'] as String? ?? e['date'] as String? ?? e['completedAt'] as String? ?? '';
          print('📊 [DASHBOARD] Checking entry date: $createdAt');
          if (createdAt.startsWith(todayStr)) {
            breathingToday++;
            print('📊 [DASHBOARD] ✅ Found today\'s exercise!');
          }
        }
        
        print('📊 [DASHBOARD] ✅ Breathing exercises today: $breathingToday');
        _metrics['breathingExercisesToday'] = breathingToday;
        
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        print('❌ [DASHBOARD] Error loading breathing exercises: $e');
        _metrics['breathingExercisesToday'] = 0;
      }
      
      // Calculate mood stability
      if (emotions.isNotEmpty) {
        print('📊 [DASHBOARD] Calculating mood stability with ${emotions.length} emotions...');
        final positiveEmotions = ['happy', 'calm', 'excited', 'grateful', 'hopeful', 'peaceful', 'content', 'optimistic', 'neutral'];
        
        final stableCount = emotions.where((e) {
          if (e is Emotion) {
            final isPositive = positiveEmotions.contains(e.emotion.toLowerCase());
            print('📊 [DASHBOARD] Emotion: ${e.emotion} - Positive: $isPositive');
            return isPositive;
          } else {
            print('⚠️ [DASHBOARD] Non-Emotion object in list: ${e.runtimeType}');
            return false;
          }
        }).length;
        
        final stability = ((stableCount / emotions.length) * 100).round();
        print('📊 [DASHBOARD] Mood stability calculated: $stability% ($stableCount/${emotions.length} positive)');
        
        _metrics['moodStability'] = stability;
        _metrics['hasEmotionData'] = true;
        _metrics['moodMessage'] = stability >= 80
            ? 'Excellent emotional stability! Keep maintaining your positive routines.'
            : stability >= 60
            ? 'Good progress on emotional wellness. Consider more relaxation activities.'
            : 'Focus on self-care activities and reach out to your support network.';
        
        print('📊 [DASHBOARD] Metrics updated: moodStability=$stability, hasEmotionData=true');
      } else {
        print('📊 [DASHBOARD] No emotions to calculate mood stability');
      }
      
      // Get journal entries
      final journalState = context.read<JournalBloc>().state;
      print('📊 [DASHBOARD] Journal state type: ${journalState.runtimeType}');
      
      int journalCount = 0;
      if (journalState is JournalLoaded) {
        journalCount = journalState.entries.length;
        print('📊 [DASHBOARD] Journal entries loaded: $journalCount items');
      }
      
      _metrics['journalEntries'] = journalCount;
      _metrics['hasJournalData'] = journalCount > 0;
      
      // Calculate task completion
      if (tasks.isNotEmpty) {
        print('📊 [DASHBOARD] Calculating task completion with ${tasks.length} tasks...');
        
        final completed = tasks.where((t) {
          if (t is Task) {
            final isCompleted = t.status == TaskStatus.completed;
            print('📊 [DASHBOARD] Task: ${t.title} - Status: ${t.status} - Completed: $isCompleted');
            return isCompleted;
          } else {
            print('⚠️ [DASHBOARD] Non-Task object in list: ${t.runtimeType}');
            return false;
          }
        }).length;
        
        final completion = ((completed / tasks.length) * 100).round();
        print('📊 [DASHBOARD] Task completion calculated: $completion% ($completed/${tasks.length} completed)');
        
        _metrics['taskCompletion'] = completion;
        _metrics['hasTaskData'] = true;
        _metrics['taskMessage'] = completion >= 80
            ? 'Outstanding task completion! You\'re crushing your goals! 🎯'
            : completion >= 60
            ? 'Great progress this week! Keep up the momentum.'
            : 'Try breaking tasks into smaller steps for better completion rates.';
        
        print('📊 [DASHBOARD] Metrics updated: taskCompletion=$completion, hasTaskData=true');
      } else {
        print('📊 [DASHBOARD] No tasks to calculate completion');
      }
      
      print('📊 [DASHBOARD] Final metrics: $_metrics');
      
      if (mounted) {
        setState(() {});
        print('✅ [DASHBOARD] UI updated with new metrics');
      }
    } catch (e, stackTrace) {
      print('❌ [DASHBOARD] Error calculating metrics: $e');
      print('❌ [DASHBOARD] Stack trace: $stackTrace');
    }
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
              child: CircularProgressIndicator(color: theme.primary),
            ),
          );
        }

        return Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: theme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with User Info
                    _buildHeader(theme),
                    const SizedBox(height: 24),

                    // Progress Reports Section (matching web app)
                    _buildProgressReports(theme),
                    const SizedBox(height: 24),

                    // Quick Actions Section
                    _buildQuickActions(theme),
                    const SizedBox(height: 24),

                    // Weekly Overview (matching web app)
                    _buildWeeklyOverview(theme),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(theme),
        );
      },
    );
  }

  Widget _buildHeader(AppTheme theme) {
    final authState = context.read<AuthBloc>().state;
    String userName = 'there';
    
    if (authState is AuthSuccess) {
      userName = authState.user.name ?? authState.user.email.split('@').first;
    }
    
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;
    
    if (hour < 12) {
      greeting = 'Good Morning';
      emoji = '☀️';
    } else if (hour < 18) {
      greeting = 'Good Afternoon';
      emoji = '🌤️';
    } else {
      greeting = 'Good Evening';
      emoji = '🌙';
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary.withOpacity(0.08), theme.secondary.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting $emoji',
            style: TextStyle(
              color: theme.text.withOpacity(0.7),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            userName,
            style: TextStyle(
              color: theme.text,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How are you feeling today?',
            style: TextStyle(
              color: theme.text.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressReports(AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: TextStyle(
            color: theme.text,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Four stat cards in a grid layout
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildCompactStatCard(
              theme,
              Icons.favorite,
              'Mood Stability',
              _metrics['hasEmotionData'] ? '${_metrics['moodStability']}%' : 'No data yet',
              Colors.red,
              _metrics['hasEmotionData'] ? _metrics['moodStability'] as int : null,
            ),
            _buildCompactStatCard(
              theme,
              Icons.center_focus_strong,
              'Task Completion',
              _metrics['hasTaskData'] ? '${_metrics['taskCompletion']}%' : 'No data yet',
              Colors.green,
              _metrics['hasTaskData'] ? _metrics['taskCompletion'] as int : null,
            ),
            _buildCompactStatCard(
              theme,
              Icons.air,
              'Breathing',
              '${_metrics['breathingExercisesToday'] ?? 0} today',
              Colors.blue,
              null,
              isBreathing: true,
            ),
            _buildCompactStatCard(
              theme,
              Icons.book,
              'Journal Entries',
              '${_metrics['journalEntries'] ?? 0} entries',
              Colors.purple,
              null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactStatCard(
    AppTheme theme,
    IconData icon,
    String title,
    String value,
    Color color,
    int? progressValue, {
    bool isBreathing = false,
  }) {
    return GestureDetector(
      onTap: isBreathing ? () => _navigateToBreathing() : null,
      child: Container(
        width: (MediaQuery.of(context).size.width - 44) / 2, // Half width minus padding and spacing
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: theme.text.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: theme.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (progressValue != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue / 100,
                  backgroundColor: theme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    AppTheme theme,
    IconData icon,
    String title,
    String value,
    String description,
    Color color,
    int? progressValue,
  ) {
    final bool isBreathing = title == 'Breathing Exercises';
    
    return GestureDetector(
      onTap: isBreathing ? () => _navigateToBreathing() : null,
      child: Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
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
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: theme.text.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          if (progressValue != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressValue / 100,
                backgroundColor: theme.border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: theme.text.withOpacity(0.7),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (isBreathing) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.arrow_forward,
                  color: theme.primary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Start Exercise',
                  style: TextStyle(
                    color: theme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }

  void _navigateToBreathing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BreathingScreen()),
    );
  }

  Widget _buildWeeklyOverview(AppTheme theme) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: theme.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Weekly Overview',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => widget.onNavigateToScreen(5),
                child: Text(
                  'View Full Report',
                  style: TextStyle(
                    color: theme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Mood Stability Bar
          _buildOverviewBar(
            theme,
            'Mood Stability',
            _metrics['moodStability'] as int,
            _metrics['moodStability'] >= 70 ? 'High' : 'Moderate',
            _metrics['moodStability'] >= 70 ? Colors.green : Colors.orange,
            '${_metrics['moodStability']}% stable emotions this week',
          ),
          const SizedBox(height: 16),
          
          // Task Completion Bar
          _buildOverviewBar(
            theme,
            'Task Completion',
            _metrics['taskCompletion'] as int,
            '${_metrics['taskCompletion']}%',
            Colors.green,
            'You\'re making good progress!',
          ),
          const SizedBox(height: 16),
          
          // Wellness Score
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Wellness Score',
                      style: TextStyle(
                        color: theme.text.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Good',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return Expanded(
                      child: Container(
                        height: 8,
                        margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: index < 4 ? Colors.yellow : theme.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  'Based on sleep & breathing habits',
                  style: TextStyle(
                    color: theme.text.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewBar(
    AppTheme theme,
    String title,
    int value,
    String label,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.text.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: theme.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: theme.text.withOpacity(0.6),
              fontSize: 12,
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

        // Row layout for all four quick actions
        Row(
          children: [
            Expanded(
              child: _buildCompactActionCard(
                theme,
                Icons.favorite_outline,
                'Emotions',
                () => _navigateToScreen(1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactActionCard(
                theme,
                Icons.check_box_outlined,
                'Tasks',
                () => _navigateToScreen(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactActionCard(
                theme,
                Icons.book_outlined,
                'Journal',
                () => _navigateToScreen(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactActionCard(
                theme,
                Icons.spa_outlined,
                'Relax',
                () => _navigateToBreathing(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactActionCard(
    AppTheme theme,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: theme.primary, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: theme.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
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
