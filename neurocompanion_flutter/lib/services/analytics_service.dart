import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neurocompanion_flutter/services/api_config.dart';

class AnalyticsData {
  final List<MoodTrendData> moodTrends;
  final List<EmotionStat> emotionDistribution;
  final AnalyticsSummary summary;

  AnalyticsData({
    required this.moodTrends,
    required this.emotionDistribution,
    required this.summary,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      moodTrends: (json['analytics'] as List? ?? [])
          .map((item) => MoodTrendData.fromJson(item))
          .toList(),
      emotionDistribution: (json['emotionDistribution'] as List? ?? [])
          .map((item) => EmotionStat.fromJson(item))
          .toList(),
      summary: AnalyticsSummary.fromJson(json),
    );
  }
}

class MoodTrendData {
  final String date;
  final String emotion;
  final double avgMood;
  final double avgConfidence;
  final int count;

  MoodTrendData({
    required this.date,
    required this.emotion,
    required this.avgMood,
    required this.avgConfidence,
    required this.count,
  });

  factory MoodTrendData.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] as Map<String, dynamic>? ?? {};
    return MoodTrendData(
      date: id['date'] ?? '',
      emotion: id['emotion'] ?? 'neutral',
      avgMood: (json['avgMood'] ?? 5).toDouble(),
      avgConfidence: (json['avgConfidence'] ?? 0.5).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class EmotionStat {
  final String emotion;
  final int count;
  final double avgMood;

  EmotionStat({
    required this.emotion,
    required this.count,
    required this.avgMood,
  });

  factory EmotionStat.fromJson(Map<String, dynamic> json) {
    return EmotionStat(
      emotion: json['_id'] ?? 'neutral',
      count: json['count'] ?? 0,
      avgMood: (json['avgMood'] ?? 5).toDouble(),
    );
  }
}

class AnalyticsSummary {
  final int totalEntries;
  final int totalEmotions;
  final double avgMood;
  final String period;

  AnalyticsSummary({
    required this.totalEntries,
    required this.totalEmotions,
    required this.avgMood,
    required this.period,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    final analytics = json['analytics'] as List? ?? [];
    final emotionDist = json['emotionDistribution'] as List? ?? [];
    
    // Calculate totals
    int totalEntries = 0;
    double totalMood = 0;
    int moodCount = 0;
    
    for (var item in analytics) {
      totalEntries += (item['count'] ?? 0) as int;
      if (item['avgMood'] != null) {
        totalMood += (item['avgMood'] as num).toDouble();
        moodCount++;
      }
    }
    
    return AnalyticsSummary(
      totalEntries: totalEntries,
      totalEmotions: emotionDist.length,
      avgMood: moodCount > 0 ? totalMood / moodCount : 5.0,
      period: json['period'] ?? '30 days',
    );
  }
}

class AnalyticsService {
  final String baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');

  Future<AnalyticsData> getJournalAnalytics(String userId, {int days = 30}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/journal/$userId/analytics?days=$days'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return AnalyticsData.fromJson(data['data']);
        }
      }
      
      throw Exception('Failed to load analytics');
    } catch (e) {
      print('Error fetching analytics: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEmotionHistory(String userId, {int days = 7}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/emotions/history/$userId/chart?days=$days'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
      
      throw Exception('Failed to load emotion history');
    } catch (e) {
      print('Error fetching emotion history: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWellnessInsights(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/wellness/insights/$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
      
      throw Exception('Failed to load wellness insights');
    } catch (e) {
      print('Error fetching wellness insights: $e');
      rethrow;
    }
  }
}
