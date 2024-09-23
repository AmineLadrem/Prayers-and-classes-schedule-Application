import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

class ClassScheduleScreen extends StatefulWidget {
  @override
  _ClassScheduleScreenState createState() => _ClassScheduleScreenState();
}

class _ClassScheduleScreenState extends State<ClassScheduleScreen> {
  final List<String> courseUrls = [
    'https://vorlesungsverzeichnis.unibas.ch/en/investigation?id=285217',
    'https://vorlesungsverzeichnis.unibas.ch/en/investigation?id=285198',
    'https://vorlesungsverzeichnis.unibas.ch/en/investigation?id=286075',
    'https://vorlesungsverzeichnis.unibas.ch/en/investigation?id=285199',
    'https://vorlesungsverzeichnis.unibas.ch/en/investigation?id=285215',
    'https://vorlesungsverzeichnis.unibas.ch/en/investigation?id=285216',
    'https://vorlesungsverzeichnis.unibas.ch/en/investigation?id=285222',
    'https://vorlesungsverzeichnis.unibas.ch/en/investigation?id=285223',
    'https://vorlesungsverzeichnis.unibas.ch/en/investigation?id=285229',
    'https://vorlesungsverzeichnis.unibas.ch/en/investigation?id=285231',
    'https://vorlesungsverzeichnis.unibas.ch/en/investigation?id=285221',
  ];
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<DateTime, List<Map<String, String>>> classScheduleMap = {};
  List<Map<String, String>> selectedDayClasses = [];
  bool isLoading = true;
  bool hasError = false;

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchAllClassSchedules();
  }

  Future<void> fetchAllClassSchedules() async {
    Map<DateTime, List<Map<String, String>>> fetchedClasses = {};

    try {
      for (String url in courseUrls) {
        final classDataList = await fetchClassSchedule(url);
        if (classDataList != null && classDataList.isNotEmpty) {
          for (var classData in classDataList) {
            final DateTime classDate =
                normalizeDate(DateTime.parse(classData['date']!));

            if (fetchedClasses.containsKey(classDate)) {
              fetchedClasses[classDate]!.add(classData);
            } else {
              fetchedClasses[classDate] = [classData];
            }
          }
        }
      }

      setState(() {
        classScheduleMap = fetchedClasses;
        selectedDayClasses =
            classScheduleMap[normalizeDate(_selectedDay)] ?? [];
        isLoading = false;

        printWeeklyCourses();
      });
    } catch (error, stackTrace) {
      print('Error fetching class schedules: $error');
      print('Stack trace: $stackTrace');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  void printWeeklyCourses() {
    DateTime today = normalizeDate(DateTime.now());
    DateTime endOfWeek = today.add(Duration(days: 7 - today.weekday));

    print("Weekly Courses from $today to $endOfWeek:");

    classScheduleMap.forEach((date, courses) {
      if (date.isAfter(today.subtract(Duration(days: 1))) &&
          date.isBefore(endOfWeek.add(Duration(days: 1)))) {
        print("Date: $date");
        courses.forEach((course) {
          print(
              "Class: ${course['title']} on ${date.toIso8601String()} at ${course['time']} in ${course['room']}");
        });
      }
    });
  }

  Future<List<Map<String, String>>?> fetchClassSchedule(String url) async {
    List<Map<String, String>> classSchedules = [];

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var document = htmlParser.parse(response.body);

        final fullClassTitle =
            document.querySelector('div.panel-heading > h2')?.text ??
                'Unknown Class Title';

        final shortenedTitle = formatClassTitle(fullClassTitle);

        final dateRows = document.querySelectorAll('div#room table tbody tr');

        if (dateRows.isNotEmpty) {
          for (var row in dateRows) {
            final cells = row.querySelectorAll('td');

            if (cells.length >= 3) {
              final dateCell = cells[0].text.trim();
              final timeCell = cells[1].text.trim();
              final roomCell = cells[2].text.trim();

              final dateParts = dateCell.split(' ');
              final dateString =
                  dateParts.length > 1 ? dateParts[1] : dateParts[0];
              final parsedDate =
                  DateTime.tryParse(dateString.split('.').reversed.join('-'));

              if (parsedDate != null) {
                classSchedules.add({
                  'title': shortenedTitle,
                  'date': parsedDate.toIso8601String(),
                  'time': timeCell,
                  'room': roomCell,
                });
              } else {
                print('Failed to parse date: $dateCell');
              }
            }
          }
        } else {
          print('No table rows found for $url');
        }
      } else {
        print(
            'Failed to fetch data from $url with status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching class data for $url: $error');
    }

    return classSchedules.isNotEmpty ? classSchedules : null;
  }

  String formatClassTitle(String fullTitle) {
    final titleParts = fullTitle.split(' - ');
    if (titleParts.length > 1) {
      String title = titleParts[1].trim();
      return title.replaceAll(RegExp(r'\d+\s*CP$'), '').trim();
    }
    return fullTitle.replaceAll(RegExp(r'\d+\s*CP$'), '').trim();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      selectedDayClasses = classScheduleMap[normalizeDate(selectedDay)] ?? [];

      print("Selected Date: $selectedDay");
      print(
          "Classes on selected date: ${selectedDayClasses.map((e) => e['title']).toList()}");
    });
  }

  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void openGoogleMaps(String location) async {
    final encodedLocation = Uri.encodeComponent(location);
    final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedLocation');
    final googleMapsAppUrl = Uri.parse('geo:0,0?q=$encodedLocation');

    try {
      // Try launching the Google Maps app first
      if (await canLaunchUrl(googleMapsAppUrl)) {
        await launchUrl(googleMapsAppUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(googleMapsUrl)) {
        // If the app is not available, open the location in the browser
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch Google Maps';
      }
    } catch (e) {
      print('Error launching Google Maps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Classes Schedule',
          style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
              ? Center(child: Text('Failed to load class schedules.'))
              : Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: _onDaySelected,
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                    ),
                    Expanded(
                      child: selectedDayClasses.isEmpty
                          ? Center(child: Text('No classes for this date.'))
                          : ListView.builder(
                              itemCount: selectedDayClasses.length,
                              itemBuilder: (context, index) {
                                selectedDayClasses.sort((a, b) {
                                  final timeA = (a['time'] ?? '00:00')
                                      .replaceAll(RegExp(r'[.-]'), ':');
                                  final timeB = (b['time'] ?? '00:00')
                                      .replaceAll(RegExp(r'[.-]'), ':');

                                  final hourA = int.parse(timeA.split(':')[0]);
                                  final minuteA =
                                      int.parse(timeA.split(':')[1]);
                                  final hourB = int.parse(timeB.split(':')[0]);
                                  final minuteB =
                                      int.parse(timeB.split(':')[1]);

                                  if (hourA == hourB) {
                                    return minuteA.compareTo(minuteB);
                                  } else {
                                    return hourA.compareTo(hourB);
                                  }
                                });

                                final classData = selectedDayClasses[index];

                                DateTime parsedDate =
                                    DateTime.parse(classData['date']!);
                                String formattedDate =
                                    "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";

                                final location =
                                    (classData['room']?.split(',')[0] ??
                                            'Unknown Location') +
                                        ', Basel';

                                return Card(
                                  margin: EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 15),
                                  child: ListTile(
                                    title:
                                        Text(classData['title'] ?? 'No title'),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Date: $formattedDate'),
                                        Text('Time: ${classData['time']}'),
                                        Text('Place: ${classData['room']}'),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.map),
                                      onPressed: () => openGoogleMaps(location),
                                    ),
                                  ),
                                );
                              },
                            ),
                    )
                  ],
                ),
    );
  }
}
