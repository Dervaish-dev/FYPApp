import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
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

                  // User Preferences
                  _buildUserPreferences(theme),
                  const SizedBox(height: 24),

                  // App Info
                  _buildAppInfo(theme),
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
        Text(
          'Settings',
          style: TextStyle(
            color: theme.text,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Customize your NeuroCompanion experience',
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
            itemCount: AppTheme.themes.length,
            itemBuilder: (context, index) {
              final themeKey = AppTheme.themes.keys.elementAt(index);
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

  Widget _buildUserPreferences(AppTheme theme) {
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
            'User Preferences',
            style: TextStyle(
              color: theme.text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Notification Settings
          ListTile(
            leading: Icon(Icons.notifications, color: theme.primary),
            title: Text(
              'Push Notifications',
              style: TextStyle(color: theme.text),
            ),
            subtitle: Text(
              'Receive reminders and updates',
              style: TextStyle(color: theme.text.withOpacity(0.7)),
            ),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                print('Notifications toggle: $value'); // Debug print
              },
              activeColor: theme.primary,
            ),
          ),

          const Divider(),

          // Data Privacy
          ListTile(
            leading: Icon(Icons.privacy_tip, color: theme.primary),
            title: Text('Data Privacy', style: TextStyle(color: theme.text)),
            subtitle: Text(
              'Manage your data and privacy settings',
              style: TextStyle(color: theme.text.withOpacity(0.7)),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: theme.text.withOpacity(0.5),
            ),
            onTap: () {
              print('Data privacy tapped'); // Debug print
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo(AppTheme theme) {
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
            'App Information',
            style: TextStyle(
              color: theme.text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ListTile(
            leading: Icon(Icons.info, color: theme.primary),
            title: Text('Version', style: TextStyle(color: theme.text)),
            subtitle: Text(
              '1.0.0',
              style: TextStyle(color: theme.text.withOpacity(0.7)),
            ),
          ),

          ListTile(
            leading: Icon(Icons.help, color: theme.primary),
            title: Text('Help & Support', style: TextStyle(color: theme.text)),
            subtitle: Text(
              'Get help and contact support',
              style: TextStyle(color: theme.text.withOpacity(0.7)),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: theme.text.withOpacity(0.5),
            ),
            onTap: () {
              print('Help & support tapped'); // Debug print
            },
          ),

          ListTile(
            leading: Icon(Icons.star, color: theme.primary),
            title: Text('Rate App', style: TextStyle(color: theme.text)),
            subtitle: Text(
              'Rate NeuroCompanion on the app store',
              style: TextStyle(color: theme.text.withOpacity(0.7)),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: theme.text.withOpacity(0.5),
            ),
            onTap: () {
              print('Rate app tapped'); // Debug print
            },
          ),
        ],
      ),
    );
  }
}
