import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neurocompanion_flutter/bloc/blocs.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/services/preferences_service.dart';
import 'package:neurocompanion_flutter/screens/forgot_password_screen.dart';
import 'package:neurocompanion_flutter/screens/notification_preferences_screen.dart';
import 'package:neurocompanion_flutter/screens/offline_status_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _twoFactorEnabled = false;

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

    // Defer until after first build so context.read works reliably.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreferences();
    });
  }

  String? _currentUserId() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthSuccess) {
      return state.user.id;
    }
    return null;
  }

  String? _toBackendThemeKey(String themeKey) {
    // Backend enum: ocean, coral, dark, mint, lavender, golden
    switch (themeKey) {
      case 'ocean':
      case 'coral':
      case 'mint':
      case 'lavender':
      case 'golden':
        return themeKey;
      case 'midnight':
        return 'dark';
      default:
        // emotion-based themes should remain local-only
        return null;
    }
  }

  String _fromBackendThemeKey(String backendTheme) {
    switch (backendTheme) {
      case 'dark':
        return 'midnight';
      case 'ocean':
      case 'coral':
      case 'mint':
      case 'lavender':
      case 'golden':
        return backendTheme;
      default:
        return 'ocean';
    }
  }

  Future<void> _loadPreferences() async {
    final authBloc = context.read<AuthBloc>();
    final prefsService = context.read<PreferencesService>();
    final themeProvider = context.read<ThemeProvider>();

    final state = authBloc.state;
    final userId = state is AuthSuccess ? state.user.id : null;
    if (userId == null || userId.isEmpty) {
      return;
    }

    try {
      final prefs = await prefsService.fetch(userId);
      final mappedTheme = _fromBackendThemeKey(prefs.defaultTheme);
      await themeProvider.setTheme(mappedTheme);
      await themeProvider.setAdaptiveMode(prefs.adaptiveMode);

      if (mounted) {
        setState(() {
          // Notification preferences are now managed in separate screen
        });
      }

      // Load 2FA status
      _loadTwoFactorStatus();
    } catch (_) {
      // Best-effort: keep local defaults if backend fetch fails.
    }
  }

  Future<void> _loadTwoFactorStatus() async {
    final state = context.read<AuthBloc>().state;
    if (state is AuthSuccess) {
      setState(() {
        _twoFactorEnabled = state.user.twoFactorEnabled ?? false;
      });
    }
  }

  Future<void> _savePreferences({
    String? themeKey,
    bool? adaptiveMode,
    bool? notificationsEnabled,
  }) async {
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) return;

    final prefsService = context.read<PreferencesService>();
    await prefsService.upsert(
      userId: userId,
      defaultTheme: themeKey,
      adaptiveMode: adaptiveMode,
      notificationsEnabled: notificationsEnabled,
    );
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

                  // Profile Information
                  _buildProfileSection(theme),
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
            itemCount: 6,
            itemBuilder: (context, index) {
              // Only show base themes (first 6), not emotion-based themes
              final baseThemeKeys = ['ocean', 'coral', 'midnight', 'mint', 'lavender', 'golden'];
              final themeKey = baseThemeKeys[index];
              final themeData = AppTheme.getTheme(themeKey);
              final isSelected = themeProvider.currentThemeKey == themeKey;

              return GestureDetector(
                onTap: () {
                  themeProvider.setTheme(themeKey);

                  final backendTheme = _toBackendThemeKey(themeKey);
                  if (backendTheme != null) {
                    _savePreferences(themeKey: backendTheme);
                  }
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

  Widget _buildProfileSection(AppTheme theme) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthSuccess) {
          return const SizedBox.shrink();
        }

        final user = state.user;

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
                'Profile Information',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildProfileItem(
                theme,
                icon: Icons.person,
                label: 'Name',
                value: user.name,
              ),
              const SizedBox(height: 12),
              _buildProfileItem(
                theme,
                icon: Icons.email,
                label: 'Email',
                value: user.email,
              ),
              if (user.age != null) ...[
                const SizedBox(height: 12),
                _buildProfileItem(
                  theme,
                  icon: Icons.cake,
                  label: 'Age',
                  value: '${user.age} years',
                ),
              ],
              if (user.gender != null && user.gender!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildProfileItem(
                  theme,
                  icon: Icons.wc,
                  label: 'Gender',
                  value: user.gender!,
                ),
              ],
              if (user.neurotype != null && user.neurotype!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildProfileItem(
                  theme,
                  icon: Icons.psychology,
                  label: 'Neurotype',
                  value: user.neurotype!,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileItem(
    AppTheme theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: theme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: theme.text.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
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
              _savePreferences(adaptiveMode: value);
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
              'Notification Preferences',
              style: TextStyle(color: theme.text),
            ),
            subtitle: Text(
              'Manage notification categories and preferences',
              style: TextStyle(color: theme.text.withOpacity(0.7)),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: theme.text.withOpacity(0.5),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPreferencesScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // Two-Factor Authentication
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is Auth2FAEnabled) {
                setState(() {
                  _twoFactorEnabled = state.enabled;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.enabled
                          ? '2FA enabled successfully!'
                          : '2FA disabled successfully',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is AuthFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: ListTile(
              leading: Icon(Icons.lock, color: theme.primary),
              title: Text(
                'Two-Factor Authentication',
                style: TextStyle(color: theme.text),
              ),
              subtitle: Text(
                'Add an extra layer of security',
                style: TextStyle(color: theme.text.withOpacity(0.7)),
              ),
              trailing: Switch(
                value: _twoFactorEnabled,
                onChanged: (value) {
                  context.read<AuthBloc>().add(Toggle2FARequested());
                },
                activeColor: theme.primary,
              ),
            ),
          ),

          const Divider(),

          // Reset Password
          ListTile(
            leading: Icon(Icons.key, color: theme.primary),
            title: Text('Reset Password', style: TextStyle(color: theme.text)),
            subtitle: Text(
              'Change your account password',
              style: TextStyle(color: theme.text.withOpacity(0.7)),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: theme.text.withOpacity(0.5),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ForgotPasswordScreen(),
                ),
              );
            },
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

          const Divider(),

          // Offline & Sync
          ListTile(
            leading: Icon(Icons.cloud_sync, color: theme.primary),
            title: Text('Offline & Sync', style: TextStyle(color: theme.text)),
            subtitle: Text(
              'Manage offline data and synchronization',
              style: TextStyle(color: theme.text.withOpacity(0.7)),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: theme.text.withOpacity(0.5),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OfflineStatusScreen(),
                ),
              );
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
