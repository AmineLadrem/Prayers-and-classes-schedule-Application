import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_time.dart';

class PrayerTimeService {
  final String baseUrl = 'https://api.aladhan.com/v1/calendarByCity';

  Future<List<PrayerTimes>> getPrayerTimes(
      String city, String country, int month, int year) async {
    final url = '$baseUrl/$year/$month?city=$city&country=$country&method=3';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      print("API Response: $data");

      if (data['data'] == null) {
        throw Exception('No data available from the API.');
      }

      List<dynamic> timesList = data['data'];
      return timesList.map((day) => PrayerTimes.fromJson(day)).toList();
    } else {
      throw Exception('Failed to load prayer times');
    }
  }
}
