import 'package:flutter/material.dart';

class TaskScheduleScreen extends StatefulWidget {
  const TaskScheduleScreen({super.key});

  @override
  State<TaskScheduleScreen> createState() => _TaskScheduleScreenState();
}

class _TaskScheduleScreenState extends State<TaskScheduleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task Schedule',
          style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 82, 26, 212),
      ),
    );
  }
}
