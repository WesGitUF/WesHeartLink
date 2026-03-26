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
  static const List<_ActivityOption> _activities = <_ActivityOption>[
    _ActivityOption(
      name: 'Running',
      emoji: '🏃',
      accent: AppColors.green,
      accentBackground: Color(0x2605DF72),
    ),
    _ActivityOption(
      name: 'Cycling',
      emoji: '🚴',
      accent: AppColors.blue,
      accentBackground: Color(0x2651A2FF),
    ),
    _ActivityOption(
      name: 'HIIT',
      emoji: '⚡',
      accent: AppColors.orange,
      accentBackground: Color(0x26FF8904),
    ),
    _ActivityOption(
      name: 'Walking',
      emoji: '🚶',
      accent: AppColors.purple,
      accentBackground: Color(0x26C27AFF),
    ),
    _ActivityOption(
      name: 'Swimming',
      emoji: '🏊',
      accent: AppColors.blue,
      accentBackground: Color(0x2651A2FF),
    ),
  ];

  String? _selectedActivity;
  String? _defaultWorkout;
  bool _userManuallySelected = false;
  bool _defaultApplied = false;
  String? _uid;

  StreamSubscription<DocumentSnapshot>? _userSub;
  StreamSubscription<User?>? _authSub;

  List<String> get _activityNames =>
      _activities.map((activity) => activity.name).toList(growable: false);

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

      if (def == null || !_activityNames.contains(def)) return;

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

    if (argDef != null && _activityNames.contains(argDef)) {
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

        if (local != null && _activityNames.contains(local)) {
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
        _selectedActivity ??= _activities.first.name;
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
      if (def != null && _activityNames.contains(def)) {
        setState(() {
          _defaultWorkout = def;
          _selectedActivity ??= def;
        });
        return;
      }

      setState(() {
        _selectedActivity ??= _activities.first.name;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedActivity ??= _activities.first.name;
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
                          child: _BackButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/home');
                            },
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
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
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
                          final bool isSelected =
                              _selectedActivity == activity.name;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ActivityCard(
                              activity: activity,
                              isSelected: isSelected,
                              isDefault: _defaultWorkout == activity.name,
                              onTap: () {
                                setState(() {
                                  _userManuallySelected = true;
                                  _selectedActivity = activity.name;
                                });
                              },
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
                bottom: 34,
                child: _ContinueButton(
                  enabled: _selectedActivity != null,
                  label: 'Continue',
                  onPressed: _handleContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.isSelected,
    required this.isDefault,
    required this.onTap,
  });

  final _ActivityOption activity;
  final bool isSelected;
  final bool isDefault;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const BorderRadius cardRadius = BorderRadius.all(Radius.circular(20));
    final List<BoxShadow> boxShadow =
        isSelected
            ? <BoxShadow>[
              BoxShadow(
                color: AppColors.green.withValues(alpha: 0.22),
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ]
            : <BoxShadow>[
              const BoxShadow(
                color: Color(0x33000000),
                blurRadius: 18,
                spreadRadius: 0,
                offset: Offset(0, 8),
              ),
            ];

    return Material(
      color: Colors.transparent,
      borderRadius: cardRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: cardRadius,
        child: Ink(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: cardRadius,
            border: Border.all(color: AppColors.strokeSoft),
            boxShadow: boxShadow,
            gradient:
                isSelected
                    ? LinearGradient(
                      begin: const Alignment(-0.95, -0.35),
                      end: const Alignment(1, 0.65),
                      colors: <Color>[
                        AppColors.green.withValues(alpha: 0.30),
                        const Color(0x9917191C),
                      ],
                    )
                    : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0x6617191C), Color(0x4D17191C)],
                    ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: activity.accentBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    activity.emoji,
                    style: const TextStyle(fontSize: 24, height: 1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        activity.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isDefault)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Default workout',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textMuted,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 18,
                      color: AppColors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow:
            enabled
                ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x59FB2C36),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: Offset(0, 12),
                  ),
                ]
                : const <BoxShadow>[],
      ),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient:
                  enabled
                      ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0xFFFF6467), AppColors.redStrong],
                      )
                      : const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0xFF3C3F44), Color(0xFF2A2C30)],
                      ),
            ),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: enabled ? AppColors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x14FFFFFF),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ActivityOption {
  const _ActivityOption({
    required this.name,
    required this.emoji,
    required this.accent,
    required this.accentBackground,
  });

  final String name;
  final String emoji;
  final Color accent;
  final Color accentBackground;
}
