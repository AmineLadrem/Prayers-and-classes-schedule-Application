import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_time.dart';

class PrayerTimeService {
  final String baseUrl = 'https://api.aladhan.com/v1/timingsByCity';

  Future<PrayerTimes> getPrayerTimes(
      String city, String country, String date) async {
    final url = '$baseUrl?city=$city&country=$country&date=$date&method=3';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PrayerTimes.fromJson(data);
    } else {
      throw Exception('Failed to load prayer times');
    }
  }
}
