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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), // height of your appbar
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: AppBar(
            backgroundColor: Colors.redAccent,
            centerTitle: true,
            leading: IconButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              }, 
              icon: const Icon(Icons.arrow_back, color: Colors.white,),
            ),
            title: Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      body: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            "Select Your Exercise",
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Divider(
            color: Colors.grey, // Optional: Set the color of the divider
            thickness: 1,      // Optional: Set the thickness of the line
            indent: 16,        // Optional: Set the empty space at the start
            endIndent: 16,     // Optional: Set the empty space at the end
          ),
          const SizedBox(height: 20),
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
                    leading: Icon(_activityIcons[activity], color: _selectedActivity == activity ? Colors.white : Colors.grey),
                    title: Text(activity, style: TextStyle(color: _selectedActivity == activity ? Colors.white : Colors.grey)),
                    tileColor: _selectedActivity == activity ? Colors.redAccent[100] : null,
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
            padding: const EdgeInsets.all(34),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedActivity == null ? null : () {
                  Navigator.pushNamed(
                    context, 
                    '/sensorSelection',
                    arguments: {
                      'workoutMode': _selectedActivity
                    }
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 24),
                ),
                // child: const Text('Next: Select Sensors'),
                child: Text(
                  'Set Up Your Sensors',
                  style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _selectedActivity == null ? Colors.grey : Colors.white
                  )
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
