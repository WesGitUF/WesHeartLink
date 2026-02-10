// TODO Implement this library.
import 'package:heart_link_app/screens/heartratedial/heartratedial_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});
  @override
  _SessionScreenState createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  String? _selectedActivity;
  String? _defaultWorkout;

  final List<String> _activities = ['Running', 'Cycling', 'HIIT', 'Walking', 'Swimming'];
    final Map<String, IconData> _activityIcons = {
    'Running': Icons.directions_run,
    'Cycling': Icons.directions_bike,
    'HIIT': Icons.fitness_center,
    'Walking': Icons.directions_walk,
    'Swimming': Icons.pool,
  };

  bool _defaultApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultApplied) return;
    _defaultApplied = true;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final def = args?['defaultWorkout'] as String?;

    //_defaultWorkout = def;

    // Preselect the default if provided and valid, otherwise pick the first option
    if (def != null && _activities.contains(def)) {
      _defaultWorkout = def;
      setState(() {
        _selectedActivity ??= def; // preselect
      });
    } else {
      // fallback: load from Firestore so "Default" still shows even if args weren't passed
      _loadDefaultWorkoutFromFirestore();

    }
    debugPrint("args defaultWorkout = $def");
    debugPrint("defaultWorkout state = $_defaultWorkout");

  }


int _token = 0;

@override
void dispose() {
  _token++;
  super.dispose();
}

Future<void> _loadDefaultWorkoutFromFirestore() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    setState(() {
      _selectedActivity ??= _activities.first;
    });
    return;
  }

  final t = ++_token;

  try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (t != _token) return;

    final def = doc.data()?['defaultWorkout'] as String?;

    setState(() {
      _defaultWorkout = (def != null && _activities.contains(def)) ? def : null;
      _selectedActivity ??= _defaultWorkout ?? _activities.first;
    });
  } catch (_) {
    if (t != _token) return;
    setState(() {
      _selectedActivity ??= _activities.first;
    });
  }
}


@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select your preferred sport')),
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
                final bool isSelected = _selectedActivity == activity;
                final bool isDefault  = _defaultWorkout == activity;
                return Card(
                  child: ListTile(
                    leading: Icon(_activityIcons[activity]),
                    title: Text(activity),
                    tileColor: isSelected ? Colors.green.withOpacity(0.15) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.withOpacity(0.2),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        if (isDefault) const SizedBox(width: 8),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
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
          // Navigate to Sensor Selection Screen with selected activity
          Navigator.pushNamed(
            context,
            '/sensor',
            arguments: {'activity': _selectedActivity}, 
          );
        },
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color.fromARGB(255, 76, 175, 80),
    padding: const EdgeInsets.symmetric(vertical: 20),
    textStyle: const TextStyle(fontSize: 24),
  ),
  child: const Text(
    'Let\'s get your sensors set up',
    style: TextStyle(color: Colors.white),
),
            ),)
          ),
        ],
      ),
    );
  }
}
