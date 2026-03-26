import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final List<String> _activities = <String>[
    'Running',
    'Cycling',
    'HIIT',
    'Walking',
    'Swimming',
  ];

  final Map<String, IconData> _activityIcons = <String, IconData>{
    'Running': Icons.directions_run,
    'Cycling': Icons.directions_bike,
    'HIIT': Icons.fitness_center,
    'Walking': Icons.directions_walk,
    'Swimming': Icons.pool,
  };

  String? _selectedActivity;
  String? _defaultWorkout;
  bool _userManuallySelected = false;
  bool _defaultApplied = false;
  String? _uid;

  StreamSubscription<DocumentSnapshot>? _userSub;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _listenForDefaultWorkoutChanges();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final String? newUid = user?.uid;
      if (newUid == _uid) return;

      _uid = newUid;
      _userSub?.cancel();
      _userSub = null;

      if (mounted) {
        setState(() {
          _defaultWorkout = null;
          _selectedActivity = null;
          _userManuallySelected = false;
          _defaultApplied = false;
        });
      } else {
        _defaultWorkout = null;
        _selectedActivity = null;
        _userManuallySelected = false;
        _defaultApplied = false;
      }

      if (newUid != null) {
        _listenForDefaultWorkoutChanges();
        _loadDefaultWorkout();
      }
    });
  }

  String? get _prefsKeyDefaultWorkout {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return 'defaultWorkout_$uid';
  }

  void _listenForDefaultWorkoutChanges() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((DocumentSnapshot snap) async {
      final Map<String, dynamic>? data = snap.data() as Map<String, dynamic>?;
      final String? def = (data?['defaultWorkout'] as String?)?.trim();

      if (def == null || !_activities.contains(def)) return;

      if (!mounted) return;
      setState(() {
        final String? oldDefault = _defaultWorkout;
        _defaultWorkout = def;

        if (!_userManuallySelected || _selectedActivity == oldDefault) {
          _selectedActivity = def;
        }
      });

      try {
        final SharedPreferences sp = await SharedPreferences.getInstance();
        final String? key = _prefsKeyDefaultWorkout;
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

    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final Object? argRaw = args?['defaultWorkout'];
    final String? argDef = argRaw is String ? argRaw.trim() : null;

    if (argDef != null && _activities.contains(argDef)) {
      _defaultWorkout = argDef;
      _selectedActivity ??= argDef;
      _loadDefaultWorkout();
      return;
    }

    _loadDefaultWorkout();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadDefaultWorkout() async {
    try {
      final String? key = _prefsKeyDefaultWorkout;
      if (key != null) {
        final SharedPreferences sp = await SharedPreferences.getInstance();
        final String? local = sp.getString(key)?.trim();

        if (local != null && _activities.contains(local)) {
          if (!mounted) return;
          setState(() {
            _defaultWorkout = local;
            _selectedActivity ??= local;
          });
          return;
        }
      }
    } catch (_) {}

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _selectedActivity ??= _activities.first;
      });
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      final String? def = (doc.data()?['defaultWorkout'] as String?)?.trim();
      if (def != null && _activities.contains(def)) {
        setState(() {
          _defaultWorkout = def;
          _selectedActivity ??= def;
        });
        return;
      }

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

  void _handleContinue() {
    final String? selectedActivity = _selectedActivity;
    if (selectedActivity == null) return;

    Navigator.pushNamed(
      context,
      '/sensorSelection',
      arguments: <String, dynamic>{'workoutMode': selectedActivity},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
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
              icon: const Icon(Icons.arrow_back, color: Colors.white),
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
        children: <Widget>[
          const SizedBox(height: 20),
          const Text(
            'Select Your Exercise',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Divider(
            color: Colors.grey,
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final String activity = _activities[index];
                final bool isSelected = _selectedActivity == activity;
                final bool isDefault = _defaultWorkout == activity;

                return Card(
                  child: ListTile(
                    leading: Icon(_activityIcons[activity]),
                    title: Text(activity),
                    tileColor: isSelected ? Colors.green.withAlpha(38) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.withAlpha(51),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
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
          Padding(
            padding: const EdgeInsets.all(34),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedActivity == null ? null : _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 24),
                ),
                child: Text(
                  'Set Up Your Sensors',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        _selectedActivity == null ? Colors.grey : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
