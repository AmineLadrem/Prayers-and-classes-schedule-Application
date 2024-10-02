import 'package:intl/intl.dart';

class PrayerTimes {
  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  PrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    if (json == null || !json.containsKey('timings')) {
      throw Exception('Invalid data structure: timings not found');
    }

    final timings = json['timings'];
    final date = DateTime.parse(json['date']['gregorian']['date']);

    return PrayerTimes(
      fajr: _parseTime(date, timings['Fajr']),
      dhuhr: _parseTime(date, timings['Dhuhr']),
      asr: _parseTime(date, timings['Asr']),
      maghrib: _parseTime(date, timings['Maghrib']),
      isha: _parseTime(date, timings['Isha']),
    );
  }

  static DateTime _parseTime(DateTime date, String time) {
    time = time.split(' ').first;
    final format = DateFormat("HH:mm");
    final timePart = format.parse(time);
    return DateTime(
        date.year, date.month, date.day, timePart.hour, timePart.minute);
  }
}
