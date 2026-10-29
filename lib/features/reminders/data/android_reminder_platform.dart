import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminders.dart';

class AndroidReminderPlatform implements ReminderPlatform {
  final plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;
  @override
  Future<void> initialize() => _initialization ??= _initialize();
  Future<void> _initialize() async {
    tzdata.initializeTimeZones();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get android => plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  @override
  Future<bool> permitted() async {
    await initialize();
    if (!(await android?.areNotificationsEnabled() ?? false)) return false;
    final channels = await android?.getNotificationChannels();
    final channel = channels
        ?.where((c) => c.id == 'freshkeep_expiry_v1')
        .firstOrNull;
    return channel == null || channel.importance != Importance.none;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (!(await android?.requestNotificationsPermission() ?? false)) {
      return false;
    }
    return permitted();
  }

  @override
  Future<String> timezone() async =>
      (await const MethodChannel('freshkeep/device')
          .invokeMethod<String>('timezone'))!;
  @override
  Future<List<PendingReminder>> pending() async {
    await initialize();
    return (await plugin.pendingNotificationRequests())
        .map((p) => PendingReminder(p.id, p.payload))
        .toList();
  }

  @override
  Future<void> cancel(int id) => plugin.cancel(id: id);
  @override
  Future<void> schedule({
    required int id,
    required DateTime localDate,
    required String zone,
    required String title,
    required String body,
    required String payload,
  }) async {
    await initialize();
    final location = tz.getLocation(zone);
    await plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      payload: payload,
      scheduledDate: tz.TZDateTime(
        location,
        localDate.year,
        localDate.month,
        localDate.day,
        localDate.hour,
        localDate.minute,
        localDate.second,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'freshkeep_expiry_v1',
          'FreshKeep expiry reminders',
          channelDescription: 'User-enabled food date reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          enableVibration: false,
          icon: 'ic_notification',
        ),
      ),
    );
  }
}
