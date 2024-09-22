import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService() {
    tz.initializeTimeZones();
  }

  Future<void> schedulePrayerNotification(
      String prayerName, String time) async {
    final DateTime now = DateTime.now();
    final DateFormat format = DateFormat('HH:mm');
    final DateTime prayerTime = format.parse(time);

    final tz.TZDateTime scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      prayerTime.hour,
      prayerTime.minute,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Prayer Reminder',
      'It\'s time for $prayerName prayer',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel',
          'Prayer Notifications',
          channelDescription: 'Channel for prayer time notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleClassNotification(
      String className, String time, String location) async {
    final DateTime now = DateTime.now();
    final DateFormat format = DateFormat('HH:mm');
    final DateTime classTime = format.parse(time);

    final tz.TZDateTime scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      classTime.hour,
      classTime.minute,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Class Reminder',
      'Your class "$className" is at $location',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'class_channel',
          'Class Notifications',
          channelDescription: 'Channel for class time notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
