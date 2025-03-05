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
  final List<String> _activities = ['Running', 'Cycling', 'HIIT', 'Walking', 'Swimming'];
    final Map<String, IconData> _activityIcons = {
    'Running': Icons.directions_run,
    'Cycling': Icons.directions_bike,
    'HIIT': Icons.fitness_center,
    'Walking': Icons.directions_walk,
    'Swimming': Icons.pool,
  };
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start New Session')),
      body: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // DropdownButton<String>(
          //   hint: const Text('Select Activity'),
          //   value: _selectedActivity,
          //   items: _activities
          //       .map((activity) => DropdownMenuItem(
          //             value: activity,
          //             child: Text(activity),
          //           ))
          //       .toList(),
          //   onChanged: (val) {
          //     setState(() {
          //       _selectedActivity = val;
          //     });
          //   },
          // ),
          //Changing Dropdown to a Card like view to match our LowFi design
          Expanded(
            child: ListView.builder(
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                String activity = _activities[index];
                return Card(
                  child: ListTile(
                    leading: Icon(_activityIcons[activity]),
                    title: Text(activity),
                    tileColor: _selectedActivity == activity ? Colors.lightBlue[100] : null,
                    onTap: () {
                      setState(() {
                        _selectedActivity = activity;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          // ElevatedButton(
          //   onPressed: _selectedActivity == null
          //       ? null
          //       : () {
          //           Navigator.pushNamed(context, '/sensorSelection');
          //         },
          //   child: const Text('Next: Select Sensors'),
          // ),
          // Changing the UI element of the button to have a green like big button similar to our Lowfi design
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedActivity == null
                    ? null
                    : () {
                        Navigator.pushNamed(context, '/sensorSelection');
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 24),
                ),
                // child: const Text('Next: Select Sensors'),
                child: const Text('Let\'s get you sensors set up'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
