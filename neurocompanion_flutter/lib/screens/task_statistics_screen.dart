import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/models/task.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/bloc/blocs.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class TaskStatisticsScreen extends StatelessWidget {
  const TaskStatisticsScreen({super.key});

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
              'Task Statistics',
              style: TextStyle(color: theme.text),
            ),
          ),
          body: BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              if (state is TaskLoading) {
                return Center(
                  child: CircularProgressIndicator(color: theme.primary),
                );
              }

              if (state is TaskLoaded) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewCards(theme, state.tasks),
                      const SizedBox(height: 24),
                      _buildCompletionChart(theme, state.tasks),
                      const SizedBox(height: 24),
                      _buildPriorityBreakdown(theme, state.tasks),
                      const SizedBox(height: 24),
                      _buildWeeklyProgress(theme, state.tasks),
                    ],
                  ),
                );
              }

              return Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: theme.text.withOpacity(0.7)),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOverviewCards(AppTheme theme, List<Task> tasks) {
    final total = tasks.length;
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
    final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final overdue = tasks.where((t) => 
      t.status != TaskStatus.completed && 
      t.dueDate != null && 
      t.dueDate!.isBefore(DateTime.now())
    ).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            color: theme.text,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(theme, 'Total', total.toString(), Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(theme, 'Done', completed.toString(), Colors.green),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(theme, 'Active', inProgress.toString(), Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(theme, 'Overdue', overdue.toString(), Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(AppTheme theme, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: theme.text.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionChart(AppTheme theme, List<Task> tasks) {
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
    final total = tasks.length;
    final percentage = total > 0 ? (completed / total * 100).toInt() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completion Rate',
            style: TextStyle(
              color: theme.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: [
                        PieChartSectionData(
                          value: completed.toDouble(),
                          title: '',
                          color: Colors.green,
                          radius: 50,
                        ),
                        PieChartSectionData(
                          value: (total - completed).toDouble(),
                          title: '',
                          color: theme.text.withOpacity(0.1),
                          radius: 50,
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Complete',
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBreakdown(AppTheme theme, List<Task> tasks) {
    final priorityCounts = {
      TaskPriority.urgent: tasks.where((t) => t.priority == TaskPriority.urgent).length,
      TaskPriority.high: tasks.where((t) => t.priority == TaskPriority.high).length,
      TaskPriority.medium: tasks.where((t) => t.priority == TaskPriority.medium).length,
      TaskPriority.low: tasks.where((t) => t.priority == TaskPriority.low).length,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Priority Breakdown',
            style: TextStyle(
              color: theme.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriorityBar(theme, 'Urgent', priorityCounts[TaskPriority.urgent]!, Colors.red),
          const SizedBox(height: 12),
          _buildPriorityBar(theme, 'High', priorityCounts[TaskPriority.high]!, Colors.orange),
          const SizedBox(height: 12),
          _buildPriorityBar(theme, 'Medium', priorityCounts[TaskPriority.medium]!, Colors.blue),
          const SizedBox(height: 12),
          _buildPriorityBar(theme, 'Low', priorityCounts[TaskPriority.low]!, Colors.green),
        ],
      ),
    );
  }

  Widget _buildPriorityBar(AppTheme theme, String label, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              count.toString(),
              style: TextStyle(
                color: theme.text.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: theme.text.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: count > 0 ? (count / 20).clamp(0.0, 1.0) : 0,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyProgress(AppTheme theme, List<Task> tasks) {
    final now = DateTime.now();
    final weekDays = List.generate(7, (index) {
      return now.subtract(Duration(days: 6 - index));
    });

    final dailyCounts = weekDays.map((day) {
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      return tasks.where((t) {
        if (t.completedAt == null) return false;
        return t.completedAt!.isAfter(dayStart) && t.completedAt!.isBefore(dayEnd);
      }).length;
    }).toList();

    final maxCount = dailyCounts.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Progress',
            style: TextStyle(
              color: theme.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final day = weekDays[index];
              final count = dailyCounts[index];
              final height = maxCount > 0 ? (count / maxCount * 100) : 0.0;

              return Column(
                children: [
                  Container(
                    width: 32,
                    height: height.clamp(4.0, 100.0),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('E').format(day).substring(0, 1),
                    style: TextStyle(
                      color: theme.text.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
