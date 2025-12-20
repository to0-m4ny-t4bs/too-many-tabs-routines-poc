import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:too_many_tabs/utils/notification_code.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final selectNotificationStream =
    StreamController<NotificationResponse>.broadcast();

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    this.data,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
  final Map<String, dynamic>? data;
}

Future<tz.TZDateTime> scheduleNotification({
  required String title,
  required String body,
  required NotificationCode id,
  required DateTime schedule,
}) async {
  const darwinNotificationDetails = DarwinNotificationDetails(
    interruptionLevel: InterruptionLevel.timeSensitive,
    sound: 'ding.aif',
  );
  const androidNotificationDetails = AndroidNotificationDetails(
    'ttt_routines',
    'ttt_routines',
    sound: RawResourceAndroidNotificationSound('ding'),
  );
  final notificationDetails = NotificationDetails(
    iOS: darwinNotificationDetails,
    android: androidNotificationDetails,
  );
  final zonedSchedule = tz.TZDateTime.from(schedule, tz.local);
  await flutterLocalNotificationsPlugin.zonedSchedule(
    id.code,
    title,
    body,
    zonedSchedule,
    notificationDetails,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
  return zonedSchedule;
}
