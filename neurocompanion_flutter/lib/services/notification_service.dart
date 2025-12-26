import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationChannel {
  tasks,
  appointments,
  medications,
  wellness,
  general,
}

class NotificationCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final bool defaultEnabled;

  const NotificationCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.defaultEnabled = true,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const List<NotificationCategory> categories = [
    NotificationCategory(
      id: 'tasks',
      name: 'Task Reminders',
      description: 'Get reminded about upcoming and overdue tasks',
      icon: Icons.task_alt,
    ),
    NotificationCategory(
      id: 'appointments',
      name: 'Appointments',
      description: 'Reminders for scheduled appointments',
      icon: Icons.calendar_today,
    ),
    NotificationCategory(
      id: 'medications',
      name: 'Medication Reminders',
      description: 'Never miss your medication schedule',
      icon: Icons.medication,
    ),
    NotificationCategory(
      id: 'wellness',
      name: 'Wellness Tips',
      description: 'Daily wellness and mental health tips',
      icon: Icons.favorite,
    ),
    NotificationCategory(
      id: 'journal',
      name: 'Journal Prompts',
      description: 'Reminders to log your thoughts and emotions',
      icon: Icons.book,
    ),
    NotificationCategory(
      id: 'breathing',
      name: 'Breathing Exercises',
      description: 'Scheduled breathing and relaxation reminders',
      icon: Icons.air,
    ),
    NotificationCategory(
      id: 'general',
      name: 'General Updates',
      description: 'App updates and important announcements',
      icon: Icons.notifications,
    ),
  ];

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannels();
    _initialized = true;
  }

  Future<void> _createNotificationChannels() async {
    final List<AndroidNotificationChannel> channels = [
      const AndroidNotificationChannel(
        'tasks',
        'Task Reminders',
        description: 'Notifications for task reminders and deadlines',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        'appointments',
        'Appointments',
        description: 'Notifications for scheduled appointments',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        'medications',
        'Medication Reminders',
        description: 'Notifications for medication schedules',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        'wellness',
        'Wellness Tips',
        description: 'Daily wellness and mental health tips',
        importance: Importance.defaultImportance,
        playSound: false,
      ),
      const AndroidNotificationChannel(
        'journal',
        'Journal Prompts',
        description: 'Reminders to log your daily thoughts',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        'breathing',
        'Breathing Exercises',
        description: 'Scheduled breathing exercise reminders',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        'general',
        'General Updates',
        description: 'App updates and announcements',
        importance: Importance.low,
        playSound: false,
      ),
    ];

    for (final channel in channels) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can be expanded to route to specific screens
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosImpl = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
    }

    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  Future<bool> isCategoryEnabled(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'notification_category_$categoryId';
    return prefs.getBool(key) ?? true;
  }

  Future<void> setCategoryEnabled(String categoryId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'notification_category_$categoryId';
    await prefs.setBool(key, enabled);

    if (!enabled) {
      // Cancel all notifications for this category
      await cancelNotificationsByCategory(categoryId);
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationChannel channel,
    String? payload,
  }) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    final categoryEnabled = await isCategoryEnabled(channel.name);
    if (!categoryEnabled) return;

    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    final androidDetails = AndroidNotificationDetails(
      channel.name,
      _getChannelName(channel),
      channelDescription: _getChannelDescription(channel),
      importance: _getImportance(channel),
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZ,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required NotificationChannel channel,
    String? payload,
  }) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    final categoryEnabled = await isCategoryEnabled(channel.name);
    if (!categoryEnabled) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    final androidDetails = AndroidNotificationDetails(
      channel.name,
      _getChannelName(channel),
      channelDescription: _getChannelDescription(channel),
      importance: _getImportance(channel),
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZ,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    required NotificationChannel channel,
    String? payload,
  }) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    final categoryEnabled = await isCategoryEnabled(channel.name);
    if (!categoryEnabled) return;

    final androidDetails = AndroidNotificationDetails(
      channel.name,
      _getChannelName(channel),
      channelDescription: _getChannelDescription(channel),
      importance: _getImportance(channel),
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelNotificationsByCategory(String category) async {
    // This is a simplified version - in production, you'd track notification IDs by category
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    for (final notification in pendingNotifications) {
      // Cancel if notification belongs to category (would need payload parsing)
      await _notifications.cancel(notification.id);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  String _getChannelName(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.tasks:
        return 'Task Reminders';
      case NotificationChannel.appointments:
        return 'Appointments';
      case NotificationChannel.medications:
        return 'Medication Reminders';
      case NotificationChannel.wellness:
        return 'Wellness Tips';
      case NotificationChannel.general:
        return 'General Updates';
    }
  }

  String _getChannelDescription(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.tasks:
        return 'Notifications for task reminders and deadlines';
      case NotificationChannel.appointments:
        return 'Notifications for scheduled appointments';
      case NotificationChannel.medications:
        return 'Notifications for medication schedules';
      case NotificationChannel.wellness:
        return 'Daily wellness and mental health tips';
      case NotificationChannel.general:
        return 'App updates and announcements';
    }
  }

  Importance _getImportance(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.appointments:
      case NotificationChannel.medications:
        return Importance.max;
      case NotificationChannel.tasks:
        return Importance.high;
      case NotificationChannel.wellness:
      case NotificationChannel.general:
        return Importance.defaultImportance;
    }
  }
}
