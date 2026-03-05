import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:heart_link_app/services/auth_service.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';
import 'package:heart_link_app/shell/app_shell.dart';
import 'package:heart_link_app/services/battery_optimization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:heart_link_app/services/workout_audio_settings.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  late final AudioPlayer _previewPlayer;
  Timer? _previewStopTimer;
  final AuthService _authService = AuthService();
  User? _user;
  bool? _isUnrestricted;
  bool _promptEnabled = true;

  // Audio File Settings
  bool _zoneAudioEnabled = true;
  String _zoneAudioAsset = WorkoutAudioSettings.defaultAsset;

  String? _previewingAsset;

  final Map<String, String> _zoneSounds = {
    'Classic': 'audio/zone_up.m4a',
    'Chimes': 'audio/zone_up_chime.m4a',
    'Popcorn': 'audio/zone_up_popcorn.m4a',
    'Radar': 'audio/zone_up_radar.m4a',
    'Soft Ding': 'audio/zone_up_ding.m4a',
  };

  final List<String> _activities = ['Running', 'Cycling', 'HIIT', 'Walking', 'Swimming'];

  final Map<String, IconData> _activityIcons = {
    'Running': Icons.directions_run,
    'Cycling': Icons.directions_bike,
    'HIIT': Icons.fitness_center,
    'Walking': Icons.directions_walk,
    'Swimming': Icons.pool,
  };


  @override
  void initState() {
    super.initState();
    _previewPlayer = AudioPlayer();

    _previewPlayer.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );

    _user = FirebaseAuth.instance.currentUser;
    WidgetsBinding.instance.addObserver(this);
    _refreshBatteryOptStatus();
    _loadPromptEnabled();
    _loadZoneAudioPrefs();

  }

  @override
  void dispose() {
    _previewStopTimer?.cancel();
    _previewPlayer.dispose();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshBatteryOptStatus();
    }
  }

  Future<void> _loadZoneAudioPrefs() async {
    final enabled = await WorkoutAudioSettings.isEnabled();
    final asset = await WorkoutAudioSettings.getAsset();

    if (!mounted) return;
    setState(() {
      _zoneAudioEnabled = enabled;
      _zoneAudioAsset = asset;
    });
  }

  Future<void> _refreshBatteryOptStatus() async {
    try {
      final v = await BatteryOptimization.isIgnoringOptimization();
      if (!mounted) return;
      setState(() => _isUnrestricted = v);

      if (v == false) {
        //final enabled = await BatteryOptimization.isPromptEnabled();
        //if (enabled) {
          //await BatteryOptimization.resetPromptOnce();
        //}
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUnrestricted = false);
    }
  }

  Future<void> _previewSound(String asset) async {
    if (!_zoneAudioEnabled) return;

    try {
      _previewStopTimer?.cancel();
      setState(() => _previewingAsset = asset);

      // Restart the preview cleanly
      await _previewPlayer.stop();
      await _previewPlayer.play(AssetSource(asset));

      _previewStopTimer = Timer(const Duration(milliseconds: 1070), () async {
        await _previewPlayer.stop();
        if (mounted) setState(() => _previewingAsset = null);
      });
    } catch (e) {
      if (mounted) {
        setState(() => _previewingAsset = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Preview failed: $e")),
        );
      }
    }
  }

  Future<void> _loadPromptEnabled() async {
    //final enabled = await BatteryOptimization.isPromptEnabled();
    if (!mounted) return;
    //setState(() => _promptEnabled = enabled);
  }

  String _labelForAsset(String asset) {
    return _zoneSounds.entries
        .firstWhere(
          (e) => e.value == asset,
      orElse: () => _zoneSounds.entries.first,
    )
        .key;
  }

  // ───────────────────────────────────────────────────────────────
  // Edit number dialog
  // ───────────────────────────────────────────────
  Future<void> _editNumberField({
    required String title,
    required String fieldName,
    required int initialValue,
    required int min,
    required int max,
    String unit = "",
  }) async {
    final ctrl = TextEditingController(
      text: initialValue > 0 ? '$initialValue' : '',
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "Enter value",
            suffixText: unit.isNotEmpty ? unit : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            child: const Text("Save"),
            onPressed: () async {
              final val = int.tryParse(ctrl.text.trim());
              if (val == null || val < min || val > max) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid value")),
                );
                return;
              }

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(user.uid)
                    .update({fieldName: val});
              }

              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // BUILD
  // ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = _user;
    final cs = Theme.of(context).colorScheme;  

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not signed in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),

      // STREAM FIRESTORE DOC ───────────────────────────────────────
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.data!.exists) {
            return const Center(child: Text("Profile not found."));
          }


          final data = snap.data!.data() as Map<String, dynamic>? ?? {};

          String? defaultWorkout;
          final raw = data['defaultWorkout'];
          if (raw is String) {
            final trimmed = raw.trim();
            if (_activities.contains(trimmed)) defaultWorkout = trimmed;
          }

          // Extract Firestore fields
          final displayName = (data['displayName'] as String?)?.trim() ?? "";
          final email = (data['email'] as String?)?.trim() ?? user.email ?? "";
          final age = data['age'] as int?;
          final weight = data['weight']?.toString();
          final gender = data['gender']?.toString();
          final photoUrl = (data['photoURL'] as String?);

          final hrAge = hrState.age;
          //final maxHr = hrState.maxHr;
          final maxHr = data['age'] != null
              ? (208 - 0.7 * (data['age'] as int)).round()
              : hrState.maxHr;

          // initial letter for avatar
          final initials = displayName.isNotEmpty
              ? displayName[0].toUpperCase()
              : (email.isNotEmpty ? email[0].toUpperCase() : "?");

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ───────────────────────────────────────────────
              // HEADER - AVATAR + NAME
              // ───────────────────────────────────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: cs.primary.withOpacity(.25),
                    backgroundImage:
                        (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      displayName.isNotEmpty ? displayName : email,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ───────────────────────────────────────────────
              // ACCOUNT
              // ───────────────────────────────────────────────
              _sectionTitle("Account"),

              ListTile(
                title: const Text("Email"),
                subtitle: Text(email),
              ),
              ListTile(
                title: const Text("Gender"),
                subtitle: Text(gender ?? "Not set"),
              ),
              ListTile(
                title: const Text("Weight"),
                subtitle: Text(weight != null ? "$weight lb" : "Not set"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editNumberField(
                  title: "Set Weight",
                  fieldName: "weight",
                  initialValue: int.tryParse(weight ?? "0") ?? 0,
                  min: 1,
                  max: 1000,
                  unit: "lb",
                ),
              ),

              const SizedBox(height: 10),

              // ───────────────────────────────────────────────
              // HEART RATE SETTINGS
              // ───────────────────────────────────────────────
              _sectionTitle("Heart Rate Settings"),

              ListTile(
                title: const Text("Age"),
                subtitle: Text(age != null ? "$age years" : "Not set"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editNumberField(
                  title: "Set Age",
                  fieldName: "age",
                  initialValue: age ?? 0,
                  min: 1,
                  max: 120,
                  unit: "years",
                ),
              ),
              ListTile(
                title: const Text("Max HR"),
                subtitle: Text("$maxHr bpm"),
              ),

              const SizedBox(height: 20),

// ───────────────────────────────────────────────
// WORKOUT PREFERENCES
// ───────────────────────────────────────────────
              _sectionTitle("Workout Preferences"),

              ListTile(
                title: const Text("Default workout"),
                subtitle: Text(defaultWorkout ?? "Not set"),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: (defaultWorkout != null && _activities.contains(defaultWorkout))
                        ? defaultWorkout
                        : _activities.first,
                    items: _activities.map((a) {
                      return DropdownMenuItem(
                        value: a,
                        child: Row(
                          children: [
                            Icon(_activityIcons[a] ?? Icons.fitness_center),
                            const SizedBox(width: 8),
                            Text(a),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) async {
                      if (v == null) return;

                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(user.uid)
                          .set({"defaultWorkout": v}, SetOptions(merge: true));

                      final sp = await SharedPreferences.getInstance();
                      await sp.setString('defaultWorkout', v);


                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Default workout set to $v")),
                      );
                    },
                  ),
                ),
              ),

              _sectionTitle("Background Tracking"),

              ListTile(
                title: const Text("Battery usage"),
                subtitle: Text(
                  _isUnrestricted == null
                      ? "Checking…"
                      : (_isUnrestricted! ? "Unrestricted" : "Optimized"),
                ),
                trailing: FilledButton(
                  onPressed: _isUnrestricted == null
                      ? null
                      : () async {
                    if (_isUnrestricted == true) {
                      if (!context.mounted) return;

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Switch back to Optimized"),
                          content: const Text(
                            "You'll be taken to Android settings.\n\n"
                            "In the list, find Heart Link and turn OFF the battery exemption "
                                "(choose Optimized / Battery optimized).",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await BatteryOptimization.openBatteryOptimizationSettings();
                              },
                              child: const Text("Open Settings"),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Optimized -> request Unrestricted using existing flow
                      await BatteryOptimization.requestIgnoreOptimization();
                      await _refreshBatteryOptStatus();
                    }
                  },
                  child: Text(
                    _isUnrestricted == true ? "Change to Optimized" : "Set Unrestricted",
                  ),
                ),
              ),

              SwitchListTile(
                title: const Text("Prompt me to enable background tracking"),
                subtitle: const Text("Shows a reminder for new sessions"),
                value: _promptEnabled,
                onChanged: (v) async {
                  setState(() => _promptEnabled = v);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(v ? "Session prompt enabled" : "Session prompt disabled")),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Audio Feedback Settings
              _sectionTitle("Audio Feedback"),

              SwitchListTile(
                title: const Text("Mute alerts when my heart rate zone increases"),
                value: !_zoneAudioEnabled,
                onChanged: (v) async {
                  final newEnabled = !v;
                  setState(() => _zoneAudioEnabled = newEnabled);
                  await WorkoutAudioSettings.setEnabled(newEnabled);
                },
              ),

              ListTile(
                title: const Text("Sound"),
                subtitle: Text(_labelForAsset(_zoneAudioAsset)),
                enabled: _zoneAudioEnabled,
                trailing: const Icon(Icons.chevron_right),
                onTap: !_zoneAudioEnabled
                    ? null
                    : () async {
                  await showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return SafeArea(
                        child: ListView(
                          children: _zoneSounds.entries.map((entry) {
                            final label = entry.key;
                            final asset = entry.value;
                            final selected = asset == _zoneAudioAsset;
                            final previewing = asset == _previewingAsset;

                            return ListTile(
                              title: Text(label),
                              leading: selected ? const Icon(Icons.check) : null,
                              trailing: IconButton(
                                icon: Icon(previewing ? Icons.stop : Icons.play_arrow),
                                onPressed: () async {
                                  if (previewing) {
                                    await _previewPlayer.stop();
                                    if (mounted) setState(() => _previewingAsset = null);
                                  } else {
                                    await _previewSound(asset);
                                  }
                                },
                              ),
                              onTap: () async {
                                // Select + preview
                                setState(() => _zoneAudioAsset = asset);
                                await WorkoutAudioSettings.setAsset(asset);
                                await _previewSound(asset);
                                if (context.mounted) Navigator.pop(context);
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),


              // ───────────────────────────────────────────────
              // SIGN OUT BUTTON
              // ───────────────────────────────────────────────
              FilledButton(
                onPressed: () async {
                  await _authService.signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: FilledButton.styleFrom(backgroundColor: cs.primary),
                  child: const Text("Sign Out"),
                  ),
                 ],
                );
               },
              ),
    );
  }

  // Section label
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color.fromARGB(180, 255, 255, 255),
        ),
      ),
    );
  }
}