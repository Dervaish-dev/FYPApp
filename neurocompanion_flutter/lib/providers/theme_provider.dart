import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color card;
  final Color text;
  final Color border;
  final Color accent;
  final Color mutedText;

  const AppTheme({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.card,
    required this.text,
    required this.border,
    required this.accent,
    required this.mutedText,
  });

  static const Map<String, AppTheme> themes = {
    // Base themes matching web app
    'ocean': AppTheme(
      name: 'Ocean Blue',
      primary: Color(0xFF0EA5E9),  // sky-500
      secondary: Color(0xFF0284C7),  // sky-600
      background: Color(0xFFF0F9FF),  // sky-50
      card: Color(0xFFE0F2FE),  // sky-100 - slightly darker than background for contrast
      text: Color(0xFF0C4A6E),  // sky-900 - dark blue for good contrast
      border: Color(0xFFBAE6FD),  // sky-200
      accent: Color(0xFF0369A1),  // sky-700
      mutedText: Color(0xFF0284C7),  // sky-600
    ),
    'coral': AppTheme(
      name: 'Coral Pink',
      primary: Color(0xFFEC4899),  // pink-500
      secondary: Color(0xFFDB2777),  // pink-600
      background: Color(0xFFFDF2F8),  // pink-50
      card: Color(0xFFFCE7F3),  // pink-100
      text: Color(0xFF831843),  // pink-900
      border: Color(0xFFFBCFE8),  // pink-200
      accent: Color(0xFFBE185D),  // pink-700
      mutedText: Color(0xFFDB2777),  // pink-600
    ),
    'midnight': AppTheme(
      name: 'Midnight Dark',
      primary: Color(0xFF64748B),  // slate-500
      secondary: Color(0xFF475569),  // slate-600
      background: Color(0xFF1E293B),  // slate-800 - dark background
      card: Color(0xFF334155),  // slate-700 - lighter for card contrast
      text: Color(0xFFF1F5F9),  // slate-100 - light text for dark bg
      border: Color(0xFF475569),  // slate-600
      accent: Color(0xFF94A3B8),  // slate-400
      mutedText: Color(0xFFCBD5E1),  // slate-300
    ),
    'mint': AppTheme(
      name: 'Mint Green',
      primary: Color(0xFF22C55E),  // green-500
      secondary: Color(0xFF16A34A),  // green-600
      background: Color(0xFFF0FDF4),  // green-50
      card: Color(0xFFDCFCE7),  // green-100
      text: Color(0xFF14532D),  // green-900
      border: Color(0xFFBBF7D0),  // green-200
      accent: Color(0xFF15803D),  // green-700
      mutedText: Color(0xFF16A34A),  // green-600
    ),
    'lavender': AppTheme(
      name: 'Lavender',
      primary: Color(0xFFA855F7),  // purple-500
      secondary: Color(0xFF9333EA),  // purple-600
      background: Color(0xFFFAF5FF),  // purple-50
      card: Color(0xFFF3E8FF),  // purple-100
      text: Color(0xFF581C87),  // purple-900
      border: Color(0xFFE9D5FF),  // purple-200
      accent: Color(0xFF7C3AED),  // purple-700
      mutedText: Color(0xFF9333EA),  // purple-600
    ),
    // Emotion-based themes for adaptive mode
    'theme-happy': AppTheme(
      name: 'Happy',
      primary: Color(0xFFFBBF24),  // amber-400
      secondary: Color(0xFFF59E0B),  // amber-500
      background: Color(0xFFFEF3C7),  // amber-100
      card: Color(0xFFFFFFFF),  // white for contrast
      text: Color(0xFF78350F),  // amber-900
      border: Color(0xFFFDE68A),  // amber-200
      accent: Color(0xFFD97706),  // amber-600
      mutedText: Color(0xFF92400E),  // amber-800
    ),
    'theme-calm': AppTheme(
      name: 'Calm',
      primary: Color(0xFFA78BFA),  // violet-400
      secondary: Color(0xFF8B5CF6),  // violet-500
      background: Color(0xFFF3F4F6),  // gray-100
      card: Color(0xFFFFFFFF),  // white
      text: Color(0xFF1F2937),  // gray-800
      border: Color(0xFFE5E7EB),  // gray-200
      accent: Color(0xFF7C3AED),  // violet-600
      mutedText: Color(0xFF6B7280),  // gray-500
    ),
    'theme-neutral': AppTheme(
      name: 'Neutral',
      primary: Color(0xFF9CA3AF),  // gray-400
      secondary: Color(0xFF6B7280),  // gray-500
      background: Color(0xFFF9FAFB),  // gray-50
      card: Color(0xFFFFFFFF),  // white
      text: Color(0xFF111827),  // gray-900
      border: Color(0xFFE5E7EB),  // gray-200
      accent: Color(0xFF4B5563),  // gray-600
      mutedText: Color(0xFF6B7280),  // gray-500
    ),
    'theme-balance': AppTheme(
      name: 'Balance',
      primary: Color(0xFF14B8A6),  // teal-500
      secondary: Color(0xFF0D9488),  // teal-600
      background: Color(0xFFF0FDFA),  // teal-50
      card: Color(0xFFFFFFFF),  // white
      text: Color(0xFF134E4A),  // teal-900
      border: Color(0xFFCCFBF1),  // teal-100
      accent: Color(0xFF0F766E),  // teal-700
      mutedText: Color(0xFF0D9488),  // teal-600
    ),
  };

  static AppTheme getTheme(String themeKey) {
    return themes[themeKey] ?? themes['ocean']!;
  }
}

class ThemeProvider extends ChangeNotifier {
  String _currentThemeKey = 'ocean';
  double _fontSize = 16.0;
  bool _adaptiveMode = false;

  String get currentThemeKey => _currentThemeKey;
  AppTheme get currentTheme => AppTheme.getTheme(_currentThemeKey);
  double get fontSize => _fontSize;
  bool get adaptiveMode => _adaptiveMode;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentThemeKey = prefs.getString('neurocompanion-theme') ?? 'ocean';
      _fontSize = prefs.getDouble('neurocompanion-fontSize') ?? 16.0;
      _adaptiveMode = prefs.getBool('neurocompanion-adaptiveMode') ?? false;
      notifyListeners();
    } catch (e) {
      print('Error loading theme settings: $e');
    }
  }

  Future<void> setTheme(String themeKey) async {
    if (AppTheme.themes.containsKey(themeKey)) {
      _currentThemeKey = themeKey;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('neurocompanion-theme', themeKey);
        print('Theme saved: $themeKey');
      } catch (e) {
        print('Error saving theme: $e');
      }
    }
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('neurocompanion-fontSize', size);
      print('Font size saved: $size');
    } catch (e) {
      print('Error saving font size: $e');
    }
  }

  Future<void> setAdaptiveMode(bool enabled) async {
    _adaptiveMode = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('neurocompanion-adaptiveMode', enabled);
      print('Adaptive mode saved: $enabled');
    } catch (e) {
      print('Error saving adaptive mode: $e');
    }
  }

  // Adaptive UI function with emotion-based theme mapping
  void applyAdaptiveTheme(String emotion) {
    if (!_adaptiveMode) return;

    const emotionThemeMap = {
      'happy': 'theme-happy',
      'sad': 'theme-calm',
      'angry': 'theme-neutral',
      'stressed': 'theme-neutral',
      'calm': 'theme-balance',
      'neutral': 'theme-balance',
      'excited': 'theme-happy',
      'worried': 'theme-neutral',
      'confused': 'theme-neutral',
      'surprised': 'theme-happy',
      'depressed': 'theme-calm',
      'anxious': 'theme-neutral',
      'frustrated': 'theme-neutral',
      'overwhelmed': 'theme-neutral',
      'lonely': 'theme-calm',
      'grateful': 'theme-happy',
      'hopeful': 'theme-happy',
      'peaceful': 'theme-balance',
      'content': 'theme-happy',
      'nervous': 'theme-neutral',
      'optimistic': 'theme-happy',
      'pessimistic': 'theme-neutral',
    };

    final newTheme = emotionThemeMap[emotion.toLowerCase()] ?? 'theme-balance';

    print('🎨 Applying adaptive theme: $emotion → $newTheme');
    setTheme(newTheme);
  }
}
