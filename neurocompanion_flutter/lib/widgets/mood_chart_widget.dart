import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/analytics_service.dart';

class MoodChartWidget extends StatelessWidget {
  final List<MoodTrendData> moodData;
  final AppTheme theme;

  const MoodChartWidget({
    super.key,
    required this.moodData,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (moodData.isEmpty) {
      return Container(
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
                color: theme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No mood data available',
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

    // Group data by date
    final Map<String, double> dailyMoods = {};
    final Map<String, int> dailyCounts = {};
    
    for (var item in moodData) {
      if (!dailyMoods.containsKey(item.date)) {
        dailyMoods[item.date] = 0;
        dailyCounts[item.date] = 0;
      }
      dailyMoods[item.date] = dailyMoods[item.date]! + item.avgMood;
      dailyCounts[item.date] = dailyCounts[item.date]! + 1;
    }

    // Calculate average mood per day
    final List<FlSpot> spots = [];
    final List<String> dates = dailyMoods.keys.toList()..sort();
    
    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final avgMood = dailyMoods[date]! / dailyCounts[date]!;
      spots.add(FlSpot(i.toDouble(), avgMood));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.border.withOpacity(0.5),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < dates.length) {
                    // Show only date (MM/DD)
                    final date = dates[index];
                    final parts = date.split('-');
                    if (parts.length == 3) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${parts[1]}/${parts[2]}',
                          style: TextStyle(
                            color: theme.text.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                reservedSize: 35,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: theme.text.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: theme.border.withOpacity(0.5),
            ),
          ),
          minX: 0,
          maxX: (dates.length - 1).toDouble(),
          minY: 0,
          maxY: 10,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: theme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: theme.primary,
                    strokeWidth: 2,
                    strokeColor: theme.background,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: theme.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
