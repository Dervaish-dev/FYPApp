import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/notification_service.dart';
import 'package:neurocompanion_flutter/screens/daily_reminder_scheduler.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final NotificationService _notificationService = NotificationService();

  bool _masterSwitch = true;
  final Map<String, bool> _categoryStates = {};
  List<PendingNotificationRequest> _pendingNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _loadPreferences();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    await _notificationService.initialize();
    final masterEnabled = await _notificationService.areNotificationsEnabled();
    final pending = await _notificationService.getPendingNotifications();

    for (final category in NotificationService.categories) {
      final enabled = await _notificationService.isCategoryEnabled(category.id);
      _categoryStates[category.id] = enabled;
    }

    setState(() {
      _masterSwitch = masterEnabled;
      _pendingNotifications = pending;
      _isLoading = false;
    });
  }

  Future<void> _toggleMasterSwitch(bool value) async {
    setState(() => _masterSwitch = value);
    await _notificationService.setNotificationsEnabled(value);

    if (value) {
      // Request permissions when enabling
      final granted = await _notificationService.requestPermissions();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable notifications in system settings'),
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _masterSwitch = false);
        await _notificationService.setNotificationsEnabled(false);
      }
    }

    await _loadPreferences();
  }

  Future<void> _toggleCategory(String categoryId, bool value) async {
    setState(() => _categoryStates[categoryId] = value);
    await _notificationService.setCategoryEnabled(categoryId, value);
    await _loadPreferences();
  }

  Future<void> _testNotification() async {
    await _notificationService.showInstantNotification(
      id: 999999,
      title: 'Test Notification',
      body: 'This is a test notification from NeuroCompanion',
      channel: NotificationChannel.general,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

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
          'Notification Preferences',
          style: TextStyle(color: theme.text),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.schedule, color: theme.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DailyReminderScheduler(),
                ),
              );
            },
            tooltip: 'Daily reminders',
          ),
          IconButton(
            icon: Icon(Icons.notifications_active, color: theme.primary),
            onPressed: _testNotification,
            tooltip: 'Send test notification',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: theme.primary),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMasterSwitch(theme),
                  const SizedBox(height: 24),
                  if (_masterSwitch) ...[
                    _buildCategoriesSection(theme),
                    const SizedBox(height: 24),
                    _buildPendingNotificationsSection(theme),
                  ] else
                    _buildDisabledMessage(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildMasterSwitch(AppTheme theme) {
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _masterSwitch ? Icons.notifications_active : Icons.notifications_off,
              color: theme.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Notifications',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _masterSwitch
                      ? 'Notifications are enabled'
                      : 'Notifications are disabled',
                  style: TextStyle(
                    color: theme.text.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _masterSwitch,
            onChanged: _toggleMasterSwitch,
            activeColor: theme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Notification Categories',
            style: TextStyle(
              color: theme.text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...NotificationService.categories.map((category) {
          return _buildCategoryCard(theme, category);
        }),
      ],
    );
  }

  Widget _buildCategoryCard(AppTheme theme, NotificationCategory category) {
    final isEnabled = _categoryStates[category.id] ?? category.defaultEnabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? theme.primary.withOpacity(0.3) : theme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEnabled
                  ? theme.primary.withOpacity(0.1)
                  : theme.text.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              category.icon,
              color: isEnabled ? theme.primary : theme.text.withOpacity(0.5),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.description,
                  style: TextStyle(
                    color: theme.text.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) => _toggleCategory(category.id, value),
            activeColor: theme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingNotificationsSection(AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scheduled Notifications',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_pendingNotifications.length}',
                  style: TextStyle(
                    color: theme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_pendingNotifications.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 48,
                    color: theme.text.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No scheduled notifications',
                    style: TextStyle(
                      color: theme.text.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              children: _pendingNotifications.take(10).map((notification) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: theme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title ?? 'Notification',
                              style: TextStyle(
                                color: theme.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (notification.body != null && notification.body!.isNotEmpty)
                              Text(
                                notification.body!,
                                style: TextStyle(
                                  color: theme.text.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildDisabledMessage(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off,
            size: 64,
            color: theme.text.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Notifications Disabled',
            style: TextStyle(
              color: theme.text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enable notifications to customize your preferences',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.text.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
