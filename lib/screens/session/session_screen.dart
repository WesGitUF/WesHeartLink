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
    final Map<String, IconData> _activityIcons = {
    'Running': Icons.directions_run,
    'Cycling': Icons.directions_bike,
    'HIIT': Icons.fitness_center,
    'Walking': Icons.directions_walk,
    // 'Swimming': Icons.pool,
  };
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 400.0;
    return Scaffold(
      appBar: AppBar(title: const Text('Select your preferred sport'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
      ),),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Step 1 of 4",
              style: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
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
                    tileColor: _selectedActivity == activity ? Colors.green[100] : null,
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
                        Navigator.pushNamed(
                          context, '/roleSelection',
                          arguments: {
                            'sport' : _selectedActivity,
                          },
                          );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: TextStyle(fontSize: 24 * scale),
                ),
                // child: const Text('Next: Select Sensors'),
                child: const Text('Let\'s get your sensors set up'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
