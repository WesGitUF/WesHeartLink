import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';
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
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: <Widget>[
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: <Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 6, 24, 140),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(<Widget>[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0x14FFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/home');
                              },
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Center(
                          child: Icon(
                            Icons.favorite_rounded,
                            size: 56,
                            color: AppColors.redStrong,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Select Your Exercise',
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'What makes your heart race?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        ..._activities.map((activity) {
                          final bool isSelected = _selectedActivity == activity;
                          final bool isDefault = _defaultWorkout == activity;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfacePrimary,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.strokeSoft),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 4,
                                ),
                                leading: Icon(
                                  _activityIcons[activity],
                                  color: AppColors.textPrimary,
                                ),
                                title: Text(
                                  activity,
                                  style: theme.textTheme.titleMedium,
                                ),
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
                                          color: AppColors.textFaint,
                                        ),
                                        child: const Text(
                                          'Default',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    if (isDefault) const SizedBox(width: 8),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppColors.green,
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    _userManuallySelected = true;
                                    _selectedActivity = activity;
                                  });
                                },
                              ),
                            ),
                          );
                        }),
                      ]),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedActivity == null ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.redStrong,
                      disabledBackgroundColor: AppColors.surfacePrimary,
                      foregroundColor: AppColors.white,
                      disabledForegroundColor: AppColors.textMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
