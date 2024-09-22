import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:todo/services/prayer_time_service.dart';
import 'package:todo/models/prayer_time.dart';
import 'package:todo/services/notifications_service.dart';

class PrayerTimesScreen extends StatefulWidget {
  @override
  _PrayerTimesScreenState createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  late Future<PrayerTimes> prayerTimes;
  Timer? _timer;
  int nextPrayerIndex = -1;
  String remainingTime = '';

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();

    _initializeNotifications();

    String currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

    prayerTimes =
        PrayerTimeService().getPrayerTimes('Basel-City', 'CH', currentDate);

    prayerTimes.then((times) {
      nextPrayerIndex = getNextPrayerIndex(times);
      startTimer(times);
      _scheduleAllPrayerNotifications(times);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  void _scheduleAllPrayerNotifications(PrayerTimes times) {
    _notificationService.schedulePrayerNotification('Fajr', times.fajr);
    _notificationService.schedulePrayerNotification('Dhuhr', times.dhuhr);
    _notificationService.schedulePrayerNotification('Asr', times.asr);
    _notificationService.schedulePrayerNotification('Maghrib', times.maghrib);
    _notificationService.schedulePrayerNotification('Isha', times.isha);
  }

  void startTimer(PrayerTimes times) {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        updateRemainingTime(times);
      });
    });
  }

  int getNextPrayerIndex(PrayerTimes times) {
    final now = TimeOfDay.now();
    List<TimeOfDay> prayerTimes = [
      _parseTime(times.fajr),
      _parseTime(times.dhuhr),
      _parseTime(times.asr),
      _parseTime(times.maghrib),
      _parseTime(times.isha),
    ];

    for (int i = 0; i < prayerTimes.length; i++) {
      if (now.hour < prayerTimes[i].hour ||
          (now.hour == prayerTimes[i].hour &&
              now.minute < prayerTimes[i].minute)) {
        return i;
      }
    }
    return 0;
  }

  TimeOfDay _parseTime(String time) {
    final timeParts = time.split(':');
    return TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
  }

  void updateRemainingTime(PrayerTimes times) {
    if (nextPrayerIndex == -1) return;

    final now = DateTime.now();
    List<String> prayerTimesList = [
      times.fajr,
      times.dhuhr,
      times.asr,
      times.maghrib,
      times.isha,
    ];

    final nextPrayerTimeStr = prayerTimesList[nextPrayerIndex];
    final nextPrayerTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(nextPrayerTimeStr.split(':')[0]),
      int.parse(nextPrayerTimeStr.split(':')[1]),
    );

    Duration diff = nextPrayerTime.difference(now);

    if (diff.isNegative) {
      nextPrayerIndex = getNextPrayerIndex(times);
    } else {
      remainingTime = formatDuration(diff);
    }
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Prayer Times',
          style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<PrayerTimes>(
          future: prayerTimes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final prayerTimes = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPrayerCard(
                      'Fajr', prayerTimes.fajr, Icons.wb_twilight, 0),
                  _buildPrayerCard(
                      'Dhuhr', prayerTimes.dhuhr, Icons.wb_sunny, 1),
                  _buildPrayerCard('Asr', prayerTimes.asr, Icons.wb_cloudy, 2),
                  _buildPrayerCard('Maghrib', prayerTimes.maghrib,
                      Icons.nightlight_round, 3),
                  _buildPrayerCard(
                      'Isha', prayerTimes.isha, Icons.brightness_3, 4),
                ],
              );
            } else {
              return Center(child: Text('No data available'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildPrayerCard(String title, String time, IconData icon, int index) {
    final bool isNextPrayer = index == nextPrayerIndex;

    return Card(
      color: isNextPrayer ? Colors.orange[100] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      margin: EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, size: 30, color: Colors.teal),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isNextPrayer ? Colors.orange : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              time,
              style: TextStyle(fontFamily: 'Roboto', fontSize: 16),
            ),
            if (isNextPrayer)
              Text(
                'Remaining time: $remainingTime',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
