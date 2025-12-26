import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/notification_service.dart';

class DailyReminderScheduler extends StatefulWidget {
  const DailyReminderScheduler({super.key});

  @override
  State<DailyReminderScheduler> createState() => _DailyReminderSchedulerState();
}

class _DailyReminderSchedulerState extends State<DailyReminderScheduler> {
  final NotificationService _notificationService = NotificationService();
  
  TimeOfDay _journalReminderTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _breathingReminderTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _wellnessReminderTime = const TimeOfDay(hour: 12, minute: 0);
  
  bool _journalReminderEnabled = false;
  bool _breathingReminderEnabled = false;
  bool _wellnessReminderEnabled = false;

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
  }

  Future<void> _selectTime(BuildContext context, TimeOfDay initialTime,
      Function(TimeOfDay) onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  Future<void> _scheduleReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required NotificationChannel channel,
  }) async {
    await _notificationService.scheduleRepeatingNotification(
      id: id,
      title: title,
      body: body,
      time: time,
      channel: channel,
    );
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
          'Daily Reminders',
          style: TextStyle(color: theme.text),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Schedule daily wellness reminders',
            style: TextStyle(
              color: theme.text.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          // Journal Reminder
          _buildReminderCard(
            theme: theme,
            icon: Icons.book,
            title: 'Journal Reminder',
            description: 'Daily reminder to log your thoughts',
            time: _journalReminderTime,
            enabled: _journalReminderEnabled,
            onToggle: (value) async {
              setState(() => _journalReminderEnabled = value);
              if (value) {
                await _scheduleReminder(
                  id: 100001,
                  title: 'Time to Journal',
                  body: 'Take a moment to reflect on your day',
                  time: _journalReminderTime,
                  channel: NotificationChannel.wellness,
                );
              } else {
                await _notificationService.cancelNotification(100001);
              }
            },
            onTimeChanged: (time) async {
              setState(() => _journalReminderTime = time);
              if (_journalReminderEnabled) {
                await _scheduleReminder(
                  id: 100001,
                  title: 'Time to Journal',
                  body: 'Take a moment to reflect on your day',
                  time: _journalReminderTime,
                  channel: NotificationChannel.wellness,
                );
              }
            },
          ),
          
          const SizedBox(height: 12),
          
          // Breathing Exercise Reminder
          _buildReminderCard(
            theme: theme,
            icon: Icons.air,
            title: 'Breathing Exercise',
            description: 'Daily breathing and relaxation reminder',
            time: _breathingReminderTime,
            enabled: _breathingReminderEnabled,
            onToggle: (value) async {
              setState(() => _breathingReminderEnabled = value);
              if (value) {
                await _scheduleReminder(
                  id: 100002,
                  title: 'Breathing Exercise',
                  body: 'Take a few minutes for mindful breathing',
                  time: _breathingReminderTime,
                  channel: NotificationChannel.wellness,
                );
              } else {
                await _notificationService.cancelNotification(100002);
              }
            },
            onTimeChanged: (time) async {
              setState(() => _breathingReminderTime = time);
              if (_breathingReminderEnabled) {
                await _scheduleReminder(
                  id: 100002,
                  title: 'Breathing Exercise',
                  body: 'Take a few minutes for mindful breathing',
                  time: _breathingReminderTime,
                  channel: NotificationChannel.wellness,
                );
              }
            },
          ),
          
          const SizedBox(height: 12),
          
          // Wellness Tip Reminder
          _buildReminderCard(
            theme: theme,
            icon: Icons.favorite,
            title: 'Wellness Tip',
            description: 'Daily wellness and mental health tips',
            time: _wellnessReminderTime,
            enabled: _wellnessReminderEnabled,
            onToggle: (value) async {
              setState(() => _wellnessReminderEnabled = value);
              if (value) {
                await _scheduleReminder(
                  id: 100003,
                  title: 'Wellness Tip',
                  body: 'Check your wellness tips for today',
                  time: _wellnessReminderTime,
                  channel: NotificationChannel.wellness,
                );
              } else {
                await _notificationService.cancelNotification(100003);
              }
            },
            onTimeChanged: (time) async {
              setState(() => _wellnessReminderTime = time);
              if (_wellnessReminderEnabled) {
                await _scheduleReminder(
                  id: 100003,
                  title: 'Wellness Tip',
                  body: 'Check your wellness tips for today',
                  time: _wellnessReminderTime,
                  channel: NotificationChannel.wellness,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard({
    required AppTheme theme,
    required IconData icon,
    required String title,
    required String description,
    required TimeOfDay time,
    required bool enabled,
    required Function(bool) onToggle,
    required Function(TimeOfDay) onTimeChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? theme.primary.withOpacity(0.3) : theme.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: enabled
                      ? theme.primary.withOpacity(0.1)
                      : theme.text.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: enabled ? theme.primary : theme.text.withOpacity(0.5),
                  size: 24,
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
                        color: theme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: theme.text.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeColor: theme.primary,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                _selectTime(context, time, onTimeChanged);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, color: theme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      time.format(context),
                      style: TextStyle(
                        color: theme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
