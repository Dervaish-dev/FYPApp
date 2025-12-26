import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/analytics_service.dart';

class EmotionPieChartWidget extends StatelessWidget {
  final List<EmotionStat> emotionStats;
  final AppTheme theme;

  const EmotionPieChartWidget({
    super.key,
    required this.emotionStats,
    required this.theme,
  });

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'excited':
        return Colors.green;
      case 'sad':
      case 'depressed':
        return Colors.blue;
      case 'calm':
        return Colors.teal;
      case 'stressed':
      case 'anxious':
        return Colors.orange;
      case 'angry':
        return Colors.red;
      case 'neutral':
        return Colors.grey;
      case 'worried':
        return Colors.amber;
      case 'surprised':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'excited':
        return Icons.celebration;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'depressed':
        return Icons.sentiment_very_dissatisfied;
      case 'calm':
        return Icons.spa;
      case 'stressed':
        return Icons.psychology_alt;
      case 'anxious':
        return Icons.warning_amber;
      case 'angry':
        return Icons.sentiment_very_dissatisfied;
      case 'neutral':
        return Icons.sentiment_neutral;
      case 'worried':
        return Icons.help_outline;
      case 'surprised':
        return Icons.lightbulb;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (emotionStats.isEmpty) {
      return Container(
        height: 250,
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
                Icons.pie_chart,
                size: 48,
                color: theme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No emotion data available',
                style: TextStyle(
                  color: theme.text.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total = emotionStats.fold<int>(0, (sum, stat) => sum + stat.count);
    
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: emotionStats.map((stat) {
                final percentage = (stat.count / total * 100);
                final color = _getEmotionColor(stat.emotion);
                
                return PieChartSectionData(
                  value: stat.count.toDouble(),
                  title: '${percentage.toStringAsFixed(0)}%',
                  color: color,
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: emotionStats.map((stat) {
            final color = _getEmotionColor(stat.emotion);
            final icon = _getEmotionIcon(stat.emotion);
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    '${stat.emotion.capitalize()} (${stat.count})',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
