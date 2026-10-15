import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notificationsPlugin =
      notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  static const String _channelId = 'daily_notes_channel';
  static const String _channelName = 'Напоминания о заметках';
  static const String _channelDescription =
      'Уведомления для запланированных заметок';

  /// Initializes local notifications and timezone data.
  Future<void> init() async {
    tz.initializeTimeZones();

    try {
      tz.setLocalLocation(tz.getLocation('Europe/Moscow'));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _notificationsPlugin.initialize(settings: settings);
  }

  /// Requests notification permissions on Android and iOS.
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      return await android?.requestNotificationsPermission() ?? false;
    }

    if (Platform.isIOS) {
      final ios = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      return await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ??
          false;
    }

    return true;
  }

  /// Schedules a notification for a note at [scheduledDate].
  Future<void> scheduleNoteNotification({
    required int noteId,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }

    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      return;
    }

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final scheduledTime = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    await _notificationsPlugin.zonedSchedule(
      id: noteId,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Cancels a scheduled notification by note ID.
  Future<void> cancelNoteNotification(int noteId) async {
    await _notificationsPlugin.cancel(id: noteId);
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}