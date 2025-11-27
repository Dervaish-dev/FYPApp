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

  const AppTheme({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.card,
    required this.text,
    required this.border,
  });

  static const Map<String, AppTheme> themes = {
    'ocean': AppTheme(
      name: 'Ocean',
      primary: Color(0xFF0EA5E9),
      secondary: Color(0xFF0284C7),
      background: Color(0xFFF0F9FF),
      card: Color(0xFFFFFFFF),
      text: Color(0xFF111827),
      border: Color(0xFFE5E7EB),
    ),
    'coral': AppTheme(
      name: 'Coral',
      primary: Color(0xFFF97316),
      secondary: Color(0xFFEA580C),
      background: Color(0xFFFFF7ED),
      card: Color(0xFFFFFFFF),
      text: Color(0xFF111827),
      border: Color(0xFFE5E7EB),
    ),
    'midnight': AppTheme(
      name: 'Midnight',
      primary: Color(0xFF6366F1),
      secondary: Color(0xFF4F46E5),
      background: Color(0xFF1E293B),
      card: Color(0xFF334155),
      text: Color(0xFFFFFFFF),
      border: Color(0xFF475569),
    ),
    'mint': AppTheme(
      name: 'Mint',
      primary: Color(0xFF10B981),
      secondary: Color(0xFF059669),
      background: Color(0xFFECFDF5),
      card: Color(0xFFFFFFFF),
      text: Color(0xFF111827),
      border: Color(0xFFE5E7EB),
    ),
    'lavender': AppTheme(
      name: 'Lavender',
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFF7C3AED),
      background: Color(0xFFFAF5FF),
      card: Color(0xFFFFFFFF),
      text: Color(0xFF111827),
      border: Color(0xFFE5E7EB),
    ),
    'golden': AppTheme(
      name: 'Golden',
      primary: Color(0xFFF59E0B),
      secondary: Color(0xFFD97706),
      background: Color(0xFFFFFBEB),
      card: Color(0xFFFFFFFF),
      text: Color(0xFF111827),
      border: Color(0xFFE5E7EB),
    ),
    // Emotion-based themes
    'theme-happy': AppTheme(
      name: 'Happy',
      primary: Color(0xFFFBBF24),
      secondary: Color(0xFFF59E0B),
      background: Color(0xFFFEF3C7),
      card: Color(0xFFFFFFFF),
      text: Color(0xFF111827),
      border: Color(0xFFFDE68A),
    ),
    'theme-calm': AppTheme(
      name: 'Calm',
      primary: Color(0xFFA78BFA),
      secondary: Color(0xFF8B5CF6),
      background: Color(0xFFF3F4F6),
      card: Color(0xFFFFFFFF),
      text: Color(0xFF111827),
      border: Color(0xFFE5E7EB),
    ),
    'theme-neutral': AppTheme(
      name: 'Neutral',
      primary: Color(0xFF9CA3AF),
      secondary: Color(0xFF6B7280),
      background: Color(0xFFF9FAFB),
      card: Color(0xFFFFFFFF),
      text: Color(0xFF111827),
      border: Color(0xFFE5E7EB),
    ),
    'theme-balance': AppTheme(
      name: 'Balance',
      primary: Color(0xFF14B8A6),
      secondary: Color(0xFF0D9488),
      background: Color(0xFFF0FDFA),
      card: Color(0xFFFFFFFF),
      text: Color(0xFF111827),
      border: Color(0xFFCCFBF1),
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
