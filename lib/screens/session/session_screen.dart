// TODO Implement this library.
//
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';



class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});
  @override
  _SessionScreenState createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  String? _selectedActivity;
  String? _defaultWorkout;

  StreamSubscription<DocumentSnapshot>? _userSub;
  bool _userManuallySelected = false;
  StreamSubscription<User?>? _authSub;
  String? _uid;



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
  void initState() {
    super.initState();

    _uid = FirebaseAuth.instance.currentUser?.uid;

    // Start listening for user doc changes (defaultWorkout)
    _listenForDefaultWorkoutChanges();

    // FIX 2: listen for auth changes so SessionScreen resets between users
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final newUid = user?.uid;

      if (newUid != _uid) {
        // user changed (sign out / sign in as different user)
        _uid = newUid;

        // stop listening to old user's Firestore doc
        _userSub?.cancel();
        _userSub = null;

        // IMPORTANT: reset session state so old defaults can't "stick"
        if (mounted) {
          setState(() {
            _defaultWorkout = null;
            _selectedActivity = null;
            _userManuallySelected = false;
            _defaultApplied = false; // allows didChangeDependencies to run again
          });
        } else {
          _defaultWorkout = null;
          _selectedActivity = null;
          _userManuallySelected = false;
          _defaultApplied = false;
        }

        // Re-listen + reload for new user (if logged in)
        if (newUid != null) {
          _listenForDefaultWorkoutChanges();
          _loadDefaultWorkout();
        }
      }
    });
  }

  String? get _prefsKeyDefaultWorkout {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return 'defaultWorkout_$uid';
  }


  void _listenForDefaultWorkoutChanges() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snap) async {
      final data = snap.data() as Map<String, dynamic>?;
      final def = (data?['defaultWorkout'] as String?)?.trim();

      if (def == null || !_activities.contains(def)) return;

      // Update UI in real-time
      if (!mounted) return;
      setState(() {
        final oldDefault = _defaultWorkout;
        _defaultWorkout = def;

        // If user hasn't manually picked something this session,
        // OR they were still on the old default, then auto-switch selection.
        if (!_userManuallySelected || _selectedActivity == oldDefault) {
          _selectedActivity = def;
        }
      });

      // Optional: keep SharedPrefs in sync so next load is instant
      try {
        final sp = await SharedPreferences.getInstance();
        final key = _prefsKeyDefaultWorkout;
        if (key != null) {
          await sp.setString(key, def);
        }

      } catch (_) {}
    });
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultApplied) return;
    _defaultApplied = true;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final argRaw = args?['defaultWorkout'];
    final argDef = (argRaw is String) ? argRaw.trim() : null;

    // If a valid defaultWorkout is passed via arguments, use it immediately
    if (argDef != null && _activities.contains(argDef)) {
      _defaultWorkout = argDef;
      _selectedActivity ??= argDef;
      // still refresh source-of-truth in background (optional)
      _loadDefaultWorkout();
      return;
    }

    // Otherwise: load default from SharedPrefs -> Firestore -> fallback
    _loadDefaultWorkout();
  }

  int _token = 0;

  @override
  void dispose() {
    _token++; // invalidate any pending async work
    _userSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }


  Future<void> _loadDefaultWorkout() async {
    // 1) SharedPreferences first (fastest)
    try {
      final key = _prefsKeyDefaultWorkout;
      if (key != null) {
        final sp = await SharedPreferences.getInstance();
        final local = sp.getString(key)?.trim();



        if (local != null && _activities.contains(local)) {
          if (!mounted) return;
          setState(() {
            _defaultWorkout = local;
            _selectedActivity ??= local;
          });
          return;
        }}
    } catch (_) {
      // ignore local read errors
    }

    // 2) Firestore fallback
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _selectedActivity ??= _activities.first;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      final def = (doc.data()?['defaultWorkout'] as String?)?.trim();

      if (def != null && _activities.contains(def)) {
        setState(() {
          _defaultWorkout = def;
          _selectedActivity ??= def;
        });
        return;
      }

      // 3) Final fallback if nothing exists
      setState(() {
        _selectedActivity ??= _activities.first;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedActivity ??= _activities.first;
      });
    }
  }



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
                          _userManuallySelected = true;
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
