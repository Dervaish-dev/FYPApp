import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return Scaffold(
          backgroundColor: theme.background,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  _buildHeader(theme),
                  const SizedBox(height: 24),

                  // Theme Selection
                  _buildThemeSection(themeProvider, theme),
                  const SizedBox(height: 24),

                  // Font Size Slider
                  _buildFontSizeSection(themeProvider, theme),
                  const SizedBox(height: 24),

                  // Adaptive UI Mode Toggle
                  _buildAdaptiveModeSection(themeProvider, theme),
                  const SizedBox(height: 24),

                  // Continue Button
                  _buildContinueButton(theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.settings, color: theme.text, size: 32),
            const SizedBox(width: 12),
            Text(
              'Settings',
              style: TextStyle(
                color: theme.text,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your preferred theme and settings',
          style: TextStyle(color: theme.text.withOpacity(0.7), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildThemeSection(ThemeProvider themeProvider, AppTheme theme) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: TextStyle(
              color: theme.text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              // Only show base themes (first 6), not emotion-based themes
              final baseThemeKeys = ['ocean', 'coral', 'midnight', 'mint', 'lavender', 'golden'];
              final themeKey = baseThemeKeys[index];
              final themeData = AppTheme.getTheme(themeKey);
              final isSelected = themeProvider.currentThemeKey == themeKey;

              return GestureDetector(
                onTap: () {
                  print('Theme selected: $themeKey'); // Debug print
                  themeProvider.setTheme(themeKey);
                },
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? themeData.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? themeData.primary : theme.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Theme color preview
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: themeData.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: themeData.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: themeData.background,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            themeData.name,
                            style: TextStyle(
                              color: theme.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(
                          Icons.check_circle,
                          color: themeData.primary,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSection(ThemeProvider themeProvider, AppTheme theme) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Font Size: ${themeProvider.fontSize.round()}px',
            style: TextStyle(
              color: theme.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.primary,
              inactiveTrackColor: theme.border,
              thumbColor: theme.primary,
              overlayColor: theme.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: themeProvider.fontSize,
              min: 12,
              max: 24,
              divisions: 12,
              onChanged: (value) {
                themeProvider.setFontSize(value);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Small',
                style: TextStyle(
                  color: theme.text.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                'Large',
                style: TextStyle(
                  color: theme.text.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveModeSection(
    ThemeProvider themeProvider,
    AppTheme theme,
  ) {
    return Container(
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
          Icon(Icons.psychology, color: theme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adaptive UI Mode',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Automatically adjust theme based on emotions',
                  style: TextStyle(
                    color: theme.text.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: themeProvider.adaptiveMode,
            onChanged: (value) {
              themeProvider.setAdaptiveMode(value);
            },
            activeColor: theme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(AppTheme theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          print(
            'Continue button pressed - navigating to main app',
          ); // Debug print
          Navigator.pushReplacementNamed(context, '/main');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Continue',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
