import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../services/prayer_time_service.dart';
import '../models/prayer_time.dart';

class PrayerTimesScreen extends StatefulWidget {
  @override
  _PrayerTimesScreenState createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  late Future<PrayerTimes> prayerTimes;
  Timer? _timer;
  int nextPrayerIndex = -1;
  String remainingTime = '';

  @override
  void initState() {
    super.initState();

    String city = 'Basel';
    String country = 'Switzerland';
    String date = DateFormat('dd-MM-yyyy').format(DateTime.now());

    prayerTimes = PrayerTimeService().getPrayerTimes(city, country, date);

    prayerTimes.then((times) {
      setState(() {
        nextPrayerIndex = getNextPrayerIndex(times);
        startTimer(times);
      });
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
      body: FutureBuilder<PrayerTimes>(
        future: prayerTimes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final times = snapshot.data!;
            return ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                String prayerName;
                DateTime prayerTime;
                IconData prayerIcon;

                switch (index) {
                  case 0:
                    prayerName = 'Fajr';
                    prayerTime = times.fajr;
                    prayerIcon = Icons.wb_twighlight;
                    break;
                  case 1:
                    prayerName = 'Dhuhr';
                    prayerTime = times.dhuhr;
                    prayerIcon = Icons.wb_sunny;
                    break;
                  case 2:
                    prayerName = 'Asr';
                    prayerTime = times.asr;
                    prayerIcon = Icons.wb_sunny_outlined;
                    break;
                  case 3:
                    prayerName = 'Maghrib';
                    prayerTime = times.maghrib;
                    prayerIcon = Icons.nights_stay;
                    break;
                  case 4:
                    prayerName = 'Isha';
                    prayerTime = times.isha;
                    prayerIcon = Icons.bedtime;
                    break;
                  default:
                    throw Exception('Invalid prayer index');
                }
                bool isNextPrayer = index == nextPrayerIndex;
                String remainingTimeText =
                    isNextPrayer ? ' - $remainingTime' : '';

                return Card(
                  color: isNextPrayer ? Colors.lightBlueAccent : Colors.white,
                  child: ListTile(
                    leading: Icon(
                      prayerIcon,
                      color: isNextPrayer ? Colors.white : Colors.teal,
                    ),
                    title: Text(
                      prayerName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isNextPrayer ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat.jm().format(prayerTime) + remainingTimeText,
                      style: TextStyle(
                        color: isNextPrayer ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('No prayer times available'));
          }
        },
      ),
    );
  }

  int getNextPrayerIndex(PrayerTimes times) {
    DateTime now = DateTime.now();
    if (now.isBefore(times.fajr)) return 0;
    if (now.isBefore(times.dhuhr)) return 1;
    if (now.isBefore(times.asr)) return 2;
    if (now.isBefore(times.maghrib)) return 3;
    if (now.isBefore(times.isha)) return 4;
    return 0;
  }

  void startTimer(PrayerTimes times) {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        nextPrayerIndex = getNextPrayerIndex(times);
        DateTime nextPrayerTime;
        switch (nextPrayerIndex) {
          case 0:
            nextPrayerTime = times.fajr;
            break;
          case 1:
            nextPrayerTime = times.dhuhr;
            break;
          case 2:
            nextPrayerTime = times.asr;
            break;
          case 3:
            nextPrayerTime = times.maghrib;
            break;
          case 4:
            nextPrayerTime = times.isha;
            break;
          default:
            throw Exception('Invalid prayer index');
        }
        remainingTime = calculateRemainingTime(nextPrayerTime);
      });
    });
  }

  String calculateRemainingTime(DateTime nextPrayer) {
    Duration duration = nextPrayer.difference(DateTime.now());
    return '${duration.inHours}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }
}
