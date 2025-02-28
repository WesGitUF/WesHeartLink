// TODO Implement this library.
//

import 'package:flutter/material.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});
  @override
  _SessionScreenState createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  String? _selectedActivity;
  final List<String> _activities = ['Running', 'Cycling', 'HIIT', 'Walking'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start New Session')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<String>(
            hint: const Text('Select Activity'),
            value: _selectedActivity,
            items: _activities
                .map((activity) => DropdownMenuItem(
                      value: activity,
                      child: Text(activity),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedActivity = val;
              });
            },
          ),
          ElevatedButton(
            onPressed: _selectedActivity == null
                ? null
                : () {
                    Navigator.pushNamed(context, '/sensorSelection');
                  },
            child: const Text('Next: Select Sensors'),
          ),
        ],
      ),
    );
  }
}
