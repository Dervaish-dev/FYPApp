import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/bloc/blocs.dart';
import 'package:neurocompanion_flutter/services/token_store.dart';
import 'package:neurocompanion_flutter/screens/login_screen.dart';

class CaregiverSettingsScreen extends StatefulWidget {
  const CaregiverSettingsScreen({Key? key}) : super(key: key);

  @override
  State<CaregiverSettingsScreen> createState() => _CaregiverSettingsScreenState();
}

class _CaregiverSettingsScreenState extends State<CaregiverSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailUpdates = true;

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      // Dispatch logout to AuthBloc to clear state
      context.read<AuthBloc>().add(LogoutRequested());

      await SharedPrefsTokenStore().clearToken();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildSectionTitle('Profile', theme),
            const SizedBox(height: 12),
            _buildSettingCard(
              theme: theme,
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.person_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    theme: theme,
                    onTap: () {
                      // TODO: Navigate to edit profile
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit profile coming soon')),
                      );
                    },
                  ),
                  _buildDivider(theme),
                  _buildSettingTile(
                    icon: Icons.lock_rounded,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    theme: theme,
                    onTap: () {
                      // TODO: Navigate to change password
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Change password coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Security Section
            _buildSectionTitle('Security', theme),
            const SizedBox(height: 12),
            _buildSettingCard(
              theme: theme,
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.shield_rounded,
                    title: 'Two-Factor Authentication',
                    subtitle: 'Manage 2FA settings',
                    theme: theme,
                    onTap: () {
                      // TODO: Navigate to 2FA settings
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('2FA settings coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notifications Section
            _buildSectionTitle('Notifications', theme),
            const SizedBox(height: 12),
            _buildSettingCard(
              theme: theme,
              child: Column(
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications_rounded,
                    title: 'Push Notifications',
                    subtitle: 'Receive updates about patients',
                    value: _notificationsEnabled,
                    theme: theme,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  _buildDivider(theme),
                  _buildSwitchTile(
                    icon: Icons.email_rounded,
                    title: 'Email Updates',
                    subtitle: 'Receive daily summary emails',
                    value: _emailUpdates,
                    theme: theme,
                    onChanged: (value) {
                      setState(() {
                        _emailUpdates = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // About Section
            _buildSectionTitle('About', theme),
            const SizedBox(height: 12),
            _buildSettingCard(
              theme: theme,
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.info_rounded,
                    title: 'App Version',
                    subtitle: '1.0.0',
                    theme: theme,
                    onTap: null,
                    showArrow: false,
                  ),
                  _buildDivider(theme),
                  _buildSettingTile(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    subtitle: 'View our privacy policy',
                    theme: theme,
                    onTap: () {
                      // TODO: Open privacy policy
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy policy coming soon')),
                      );
                    },
                  ),
                  _buildDivider(theme),
                  _buildSettingTile(
                    icon: Icons.description_rounded,
                    title: 'Terms of Service',
                    subtitle: 'View our terms',
                    theme: theme,
                    onTap: () {
                      // TODO: Open terms of service
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terms of service coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Logout Button
            _buildSettingCard(
              theme: theme,
              child: _buildSettingTile(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                theme: theme,
                onTap: _handleLogout,
                titleColor: Colors.red,
                iconColor: Colors.red,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required ThemeData theme,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
    required VoidCallback? onTap,
    bool showArrow = true,
    Color? titleColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? theme.primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: iconColor ?? theme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textTheme.bodyLarge?.color?.withOpacity(0.3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ThemeData theme,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: theme.dividerColor.withOpacity(0.1),
    );
  }
}
