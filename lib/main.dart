import 'package:flutter/material.dart';
import 'package:todo/screens/prayer_times_screen.dart';
import 'package:todo/screens/class_schedule_screen.dart';
import 'package:todo/screens/task_schedule_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Amine App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  static final List<Widget> _screens = <Widget>[
    PrayerTimesScreen(),
    ClassScheduleScreen(),
    TaskScheduleScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Prayer Times',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Class Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_task_rounded),
            label: 'Task Schedule',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: _selectedIndex == 0
            ? Colors.teal
            : _selectedIndex == 1
                ? Color.fromARGB(255, 3, 165, 194)
                : Color.fromARGB(255, 82, 26, 212),
        onTap: _onItemTapped,
      ),
    );
  }
}
