import 'package:flutter/material.dart';

import 'dart:async';
import 'package:intl/intl.dart';
import 'package:todo/services/prayer_time_service.dart';
import 'package:todo/models/prayer_time.dart';

class PrayerTimesScreen extends StatefulWidget {
  @override
  _PrayerTimesScreenState createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  late Future<List<PrayerTimes>> prayerTimes;
  Timer? _timer;
  int nextPrayerIndex = -1;
  String remainingTime = '';

  @override
  void initState() {
    super.initState();

    int currentMonth = DateTime.now().month;
    int currentYear = DateTime.now().year;

    prayerTimes = PrayerTimeService()
        .getPrayerTimes('Basel', 'CH', currentMonth, currentYear);

    prayerTimes.then((times) {
      nextPrayerIndex = getNextPrayerIndex(times);
      startTimer(times);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prayer Times'),
      ),
      body: Center(
        child: FutureBuilder<List<PrayerTimes>>(
          future: prayerTimes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              final times = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildPrayerCard('Fajr', times[0].fajr, Icons.wb_sunny, 0),
                  _buildPrayerCard(
                      'Dhuhr', times[0].dhuhr, Icons.brightness_7, 1),
                  _buildPrayerCard('Asr', times[0].asr, Icons.brightness_5, 2),
                  _buildPrayerCard(
                      'Maghrib', times[0].maghrib, Icons.brightness_4, 3),
                  _buildPrayerCard(
                      'Isha', times[0].isha, Icons.brightness_3, 4),
                ],
              );
            } else {
              return Text('No data available');
            }
          },
        ),
      ),
    );
  }

  Widget _buildPrayerCard(
      String title, DateTime time, IconData icon, int index) {
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
              DateFormat.jm().format(time),
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

  int getNextPrayerIndex(List<PrayerTimes> prayerTimes) {
    DateTime now = DateTime.now();
    if (now.isBefore(prayerTimes[0].fajr)) return 0;
    if (now.isBefore(prayerTimes[0].dhuhr)) return 1;
    if (now.isBefore(prayerTimes[0].asr)) return 2;
    if (now.isBefore(prayerTimes[0].maghrib)) return 3;
    if (now.isBefore(prayerTimes[0].isha)) return 4;
    return -1;
  }

  void startTimer(List<PrayerTimes> prayerTimes) {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        if (nextPrayerIndex == 0) {
          remainingTime = calculateRemainingTime(prayerTimes[0].fajr);
        } else if (nextPrayerIndex == 1) {
          remainingTime = calculateRemainingTime(prayerTimes[0].dhuhr);
        } else if (nextPrayerIndex == 2) {
          remainingTime = calculateRemainingTime(prayerTimes[0].asr);
        } else if (nextPrayerIndex == 3) {
          remainingTime = calculateRemainingTime(prayerTimes[0].maghrib);
        } else if (nextPrayerIndex == 4) {
          remainingTime = calculateRemainingTime(prayerTimes[0].isha);
        } else {
          remainingTime = 'No upcoming prayers';
        }
      });
    });
  }

  String calculateRemainingTime(DateTime nextPrayer) {
    Duration duration = nextPrayer.difference(DateTime.now());
    return '${duration.inHours}:${duration.inMinutes.remainder(60)}:${duration.inSeconds.remainder(60)}';
  }
}
