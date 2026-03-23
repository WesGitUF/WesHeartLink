import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:heart_link_app/services/auth_service.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';
import 'package:heart_link_app/shell/app_shell.dart';
import 'package:heart_link_app/services/battery_optimization.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:heart_link_app/services/workout_audio_settings.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:heart_link_app/services/workout_haptic_settings.dart';
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
  bool? _notifAllowed;

  // Audio File Settings
  bool _zoneAudioEnabled = true;
  String _zoneAudioAsset = WorkoutAudioSettings.defaultAsset;

  bool _zoneHapticEnabled = true;

  String? _previewingAsset;

  // Theme colors for profile UI
  // Shared profile colors
  Color get _cardColor => Colors.white.withOpacity(0.04);
  Color get _cardBorderColor => Colors.white.withOpacity(0.06);
  Color get _cardShadowColor => Colors.black.withOpacity(0.28);
  Color get _primaryActionColor => Colors.redAccent.withOpacity(0.25);
  Color get _primaryActionBorder => Colors.white.withOpacity(0.08);
  Color get _secondaryTextColor => Colors.white70;
  Color get _chevronColor => Colors.white54;

  final Map<String, String> _zoneSounds = {
    'Classic': 'audio/zone_up.m4a',
    'Chimes': 'audio/zone_up_chime.m4a',
    'Popcorn': 'audio/zone_up_popcorn.m4a',
    'Radar': 'audio/zone_up_radar.m4a',
    'Soft Ding': 'audio/zone_up_ding.m4a',
  };

  final List<String> _activities = [
    'Running',
    'Cycling',
    'HIIT',
    'Walking',
    'Swimming'
  ];

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

    _refreshBackgroundTrackingStatus();
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
      _refreshBackgroundTrackingStatus();
    }
  }

  Future<void> _loadZoneAudioPrefs() async {
    final enabled = await WorkoutAudioSettings.isEnabled();
    final asset = await WorkoutAudioSettings.getAsset();
    final hapticEnabled = await WorkoutHapticSettings.isEnabled();

    if (!mounted) return;
    setState(() {
      _zoneAudioEnabled = enabled;
      _zoneAudioAsset = asset;
      _zoneHapticEnabled = hapticEnabled;
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

  Future<void> _refreshNotificationStatus() async {
    try {
      final status = await Permission.notification.status;
      if (!mounted) return;
      setState(() => _notifAllowed = status.isGranted);
    } catch (_) {
      if (!mounted) return;
      setState(() => _notifAllowed = false);
    }
  }

  Future<void> _refreshBackgroundTrackingStatus() async {
    await _refreshBatteryOptStatus();
    await _refreshNotificationStatus();
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
      builder: (_) =>
          AlertDialog(
            backgroundColor: const Color.fromARGB(255, 18, 18, 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: _cardBorderColor,
                width: 1.1,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700
              )
            ),
            content: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.redAccent,
              decoration: InputDecoration(
                hintText: "Enter value",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                suffixText: unit.isNotEmpty ? unit : null,
                suffixStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: _cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _cardBorderColor,
                    width: 1.1,
                  ),
                ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.redAccent.withOpacity(0.35),
                      width: 1.2,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryActionColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: _primaryActionBorder,
                      width: 1,
                    ),
                  ),
                ),
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
                child: const Text("Save"),
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
    final cs = Theme
        .of(context)
        .colorScheme;

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

          final displayName = (data['displayName'] as String?)?.trim() ?? "";
          final email = (data['email'] as String?)?.trim() ?? user.email ?? "";
          final age = data['age'] as int?;
          final weight = data['weight']?.toString();
          final gender = data['gender']?.toString();
          final photoUrl = data['photoURL'] as String?;

          final maxHr = age != null
              ? (208 - 0.7 * age).round()
              : hrState.maxHr;

          final initials = displayName.isNotEmpty
              ? displayName[0].toUpperCase()
              : (email.isNotEmpty ? email[0].toUpperCase() : "?");

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(
                  displayName: displayName,
                  email: email,
                  photoUrl: photoUrl,
                  initials: initials,
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _buildTopInfoCard(
                        icon: Icons.cake_outlined,
                        iconColor: Colors.greenAccent,
                        value: age != null ? "$age" : "Not set",
                        onTap: () => _editNumberField(
                          title: "Set Age",
                          fieldName: "age",
                          initialValue: age ?? 0,
                          min: 1,
                          max: 120,
                          unit: "years",
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTopInfoCard(
                        icon: Icons.person_outline,
                        iconColor: Colors.blueAccent,
                        value: gender ?? "Not set",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTopInfoCard(
                        icon: Icons.monitor_weight_outlined,
                        iconColor: Colors.orangeAccent,
                        value: weight != null ? "$weight lb" : "Not set",
                        onTap: () => _editNumberField(
                          title: "Set Weight",
                          fieldName: "weight",
                          initialValue: int.tryParse(weight ?? "0") ?? 0,
                          min: 1,
                          max: 1000,
                          unit: "lb",
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const Text(
                  "Settings",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 14),

                _buildMenuCard(
                  icon: Icons.person_outline,
                  iconColor: Colors.blueAccent,
                  title: "Account",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AccountScreen(
                          displayName: displayName,
                          email: email,
                          gender: gender,
                          weight: weight,
                          photoUrl: photoUrl,
                          initials: initials,
                          onEditWeight: () => _editNumberField(
                            title: "Set Weight",
                            fieldName: "weight",
                            initialValue: int.tryParse(weight ?? "0") ?? 0,
                            min: 1,
                            max: 1000,
                            unit: "lb",
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _buildMenuCard(
                  icon: Icons.favorite_outline,
                  iconColor: Colors.redAccent,
                  title: "Heart Rate Info",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HeartRateInfoScreen(
                          age: age,
                          maxHr: maxHr,
                          onEditAge: () => _editNumberField(
                            title: "Set Age",
                            fieldName: "age",
                            initialValue: age ?? 0,
                            min: 1,
                            max: 120,
                            unit: "years",
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _buildMenuCard(
                  icon: Icons.bluetooth_outlined,
                  iconColor: Colors.purpleAccent,
                  title: "Device",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeviceScreen(
                          isUnrestricted: _isUnrestricted,
                          notifAllowed: _notifAllowed,
                          zoneAudioEnabled: _zoneAudioEnabled,
                          zoneHapticEnabled: _zoneHapticEnabled,
                          zoneAudioAsset: _zoneAudioAsset,
                          previewingAsset: _previewingAsset,
                          zoneSounds: _zoneSounds,
                          labelForAsset: _labelForAsset,

                          onBatteryTap: () async {
                            if (_isUnrestricted == null) return;

                            if (_isUnrestricted == true) {
                              if (!context.mounted) return;

                              await showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Manage battery setting"),
                                  content: const Text(
                                    "You'll be taken to Android settings.\n\n"
                                        "To reduce battery use, you can switch Heart Link back to Optimized.\n"
                                        "To keep tracking reliable, leave it on Unrestricted.",
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
                              if (!context.mounted) return;

                              await showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Allow unrestricted battery use"),
                                  content: const Text(
                                    "You'll be taken to Android settings.\n\n"
                                        "Set Heart Link to Unrestricted so workout tracking is more reliable in the background.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await BatteryOptimization.openAppSettings();
                                      },
                                      child: const Text("Open Settings"),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },

                          onNotificationTap: () async {
                            if (_notifAllowed == null) return;

                            if (_notifAllowed == true) {
                              await openAppSettings();
                            } else {
                              await Permission.notification.request();
                              await _refreshBackgroundTrackingStatus();
                            }
                          },

                          onToggleMute: (bool v) async {
                            final newEnabled = !v;
                            setState(() => _zoneAudioEnabled = newEnabled);
                            await WorkoutAudioSettings.setEnabled(newEnabled);
                          },

                          onToggleHaptics: (bool v) async {
                            final newEnabled = !v;
                            setState(() => _zoneHapticEnabled = newEnabled);
                            await WorkoutHapticSettings.setEnabled(newEnabled);
                          },

                          onSelectSound: (String asset) async {
                            setState(() => _zoneAudioAsset = asset);
                            await WorkoutAudioSettings.setAsset(asset);
                            await _previewSound(asset);
                          },

                          onPreviewSound: (String asset) async {
                            await _previewSound(asset);
                          },

                          onStopPreview: () async {
                            await _previewPlayer.stop();
                            if (mounted) {
                              setState(() => _previewingAsset = null);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _buildMenuCard(
                  icon: Icons.settings_outlined,
                  iconColor: Colors.greenAccent,
                  title: "Preferences",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PreferencesScreen(
                          defaultWorkout: defaultWorkout,
                          activities: _activities,
                          activityIcons: _activityIcons,
                          onWorkoutChanged: (String v) async {
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
                    );
                  },
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.25),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                    ),
                    onPressed: () async {
                      await _authService.signOut();
                      if (!context.mounted) return;
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      "Sign Out",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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

  Widget _buildProfileHeader({
    required String displayName,
    required String email,
    required String? photoUrl,
    required String initials,
  }) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white10,
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                ? NetworkImage(photoUrl)
                : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Text(
              initials,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            displayName.isNotEmpty ? displayName : "No Name",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopInfoCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    VoidCallback? onTap,
  }) {
    final isEditable = onTap != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: Colors.white.withOpacity(0.03),
          highlightColor: Colors.white.withOpacity(0.02),
          child: SizedBox(
            height: 100,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: iconColor, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                if (isEditable)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.white.withOpacity(0.04),
          highlightColor: Colors.white.withOpacity(0.02),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildSectionCard({
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 6),
}) {
  return Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Colors.white.withOpacity(0.06),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.28),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

// Account Settings
class AccountScreen extends StatefulWidget {
  final String displayName;
  final String email;
  final String? gender;
  final String? weight;
  final String? photoUrl;
  final String initials;
  final Future<void> Function() onEditWeight;

  const AccountScreen({
    super.key,
    required this.displayName,
    required this.email,
    required this.gender,
    required this.weight,
    required this.photoUrl,
    required this.initials,
    required this.onEditWeight,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _currentWeight;

  @override
  void initState() {
    super.initState();
    _currentWeight = widget.weight;
  }

  Future<void> _reloadWeight() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (!mounted || data == null) return;

    setState(() {
      _currentWeight = data['weight']?.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white10,
                  backgroundImage:
                  (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                      ? NetworkImage(widget.photoUrl!)
                      : null,
                  child: (widget.photoUrl == null || widget.photoUrl!.isEmpty)
                      ? Text(
                    widget.initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  widget.displayName.isNotEmpty ? widget.displayName : "No Name",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionCard(
            child: Column(
              children: [
                ListTile(
                  title: const Text("Name"),
                  subtitle: Text(
                    widget.displayName.isNotEmpty ? widget.displayName : "Not set",
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.06)),
                ListTile(
                  title: const Text("Email"),
                  subtitle: Text(widget.email),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.06)),
                ListTile(
                  title: const Text("Gender"),
                  subtitle: Text(widget.gender ?? "Not set"),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.06)),
                ListTile(
                  title: const Text("Weight"),
                  subtitle: Text(
                    _currentWeight != null ? "$_currentWeight lb" : "Not set",
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                  onTap: () async {
                    await widget.onEditWeight();
                    await _reloadWeight();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// Heart Rate Settings
class HeartRateInfoScreen extends StatefulWidget {
  final int? age;
  final int maxHr;
  final Future<void> Function() onEditAge;

  const HeartRateInfoScreen({
    super.key,
    required this.age,
    required this.maxHr,
    required this.onEditAge,
  });

  @override
  State<HeartRateInfoScreen> createState() => _HeartRateInfoScreenState();
}

class _HeartRateInfoScreenState extends State<HeartRateInfoScreen> {
  int? _currentAge;
  int _currentMaxHr = 0;

  @override
  void initState() {
    super.initState();
    _currentAge = widget.age;
    _currentMaxHr = widget.maxHr;
  }

  Future<void> _reloadAge() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (!mounted || data == null) return;

    final age = data['age'] as int?;
    setState(() {
      _currentAge = age;
      _currentMaxHr = age != null ? (208 - 0.7 * age).round() : hrState.maxHr;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Heart Rate Info")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionCard(
            child: Column(
              children: [
                ListTile(
                  title: const Text("Age"),
                  subtitle: Text(
                    _currentAge != null ? "$_currentAge years" : "Not set",
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                  onTap: () async {
                    await widget.onEditAge();
                    await _reloadAge();
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.06)),
                ListTile(
                  title: const Text("Max HR"),
                  subtitle: Text("$_currentMaxHr bpm"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// Device Settings
class DeviceScreen extends StatefulWidget {
  final bool? isUnrestricted;
  final bool? notifAllowed;
  final bool zoneAudioEnabled;
  final bool zoneHapticEnabled;
  final String zoneAudioAsset;
  final String? previewingAsset;

  final Map<String, String> zoneSounds;
  final String Function(String asset) labelForAsset;

  final Future<void> Function() onBatteryTap;
  final Future<void> Function() onNotificationTap;
  final Future<void> Function(bool value) onToggleMute;
  final Future<void> Function(bool value) onToggleHaptics;
  final Future<void> Function(String asset) onSelectSound;
  final Future<void> Function(String asset) onPreviewSound;
  final Future<void> Function() onStopPreview;

  const DeviceScreen({
    super.key,
    required this.isUnrestricted,
    required this.notifAllowed,
    required this.zoneAudioEnabled,
    required this.zoneHapticEnabled,
    required this.zoneAudioAsset,
    required this.previewingAsset,
    required this.zoneSounds,
    required this.labelForAsset,
    required this.onBatteryTap,
    required this.onNotificationTap,
    required this.onToggleMute,
    required this.onToggleHaptics,
    required this.onSelectSound,
    required this.onPreviewSound,
    required this.onStopPreview,
  });

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen>
    with WidgetsBindingObserver {
  bool? _isUnrestricted;
  bool? _notifAllowed;
  bool _zoneAudioEnabled = true;
  bool _zoneHapticEnabled = true;
  String _zoneAudioAsset = WorkoutAudioSettings.defaultAsset;
  String? _previewingAsset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _isUnrestricted = widget.isUnrestricted;
    _notifAllowed = widget.notifAllowed;
    _zoneAudioEnabled = widget.zoneAudioEnabled;
    _zoneHapticEnabled = widget.zoneHapticEnabled;
    _zoneAudioAsset = widget.zoneAudioAsset;
    _previewingAsset = widget.previewingAsset;
  }

  @override
  void didUpdateWidget(covariant DeviceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isUnrestricted = widget.isUnrestricted;
    _notifAllowed = widget.notifAllowed;
    _zoneAudioEnabled = widget.zoneAudioEnabled;
    _zoneHapticEnabled = widget.zoneHapticEnabled;
    _zoneAudioAsset = widget.zoneAudioAsset;
    _previewingAsset = widget.previewingAsset;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatuses();
    }
  }

  Future<void> _refreshStatuses() async {
    try {
      final unrestricted = await BatteryOptimization.isIgnoringOptimization();
      final notifStatus = await Permission.notification.status;
      if (!mounted) return;

      setState(() {
        _isUnrestricted = unrestricted;
        _notifAllowed = notifStatus.isGranted;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Devices")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Background Tracking",
            style: TextStyle(
              fontSize: 14,
              color: Color.fromARGB(180, 255, 255, 255),
            ),
          ),
          const SizedBox(height: 8),

          _buildSectionCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text("Battery optimization"),
                  subtitle: Text(
                    _isUnrestricted == null
                        ? "Checking…"
                        : (_isUnrestricted! ? "Unrestricted" : "Optimized"),
                  ),
                  trailing: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.25),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                    ),
                    onPressed: _isUnrestricted == null
                        ? null
                        : () async {
                      await widget.onBatteryTap();
                      await _refreshStatuses();
                    },
                    child: Text(
                      _isUnrestricted == true ? "Manage" : "Set Unrestricted",
                    ),
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.06)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text("Workout notifications"),
                  subtitle: Text(
                    _notifAllowed == null
                        ? "Checking…"
                        : (_notifAllowed! ? "Allowed" : "Off"),
                  ),
                  trailing: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.25),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                    ),
                    onPressed: _notifAllowed == null
                        ? null
                        : () async {
                      await widget.onNotificationTap();
                      await _refreshStatuses();
                    },
                    child: Text(
                      _notifAllowed == true ? "Manage" : "Allow",
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: Text(
                    "Heart Link uses workout notification and battery settings to track your workout reliably.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            "Audio Feedback",
            style: TextStyle(
              fontSize: 14,
              color: Color.fromARGB(180, 255, 255, 255),
            ),
          ),
          const SizedBox(height: 8),

          _buildSectionCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Mute alerts when my heart rate zone increases"),
                  value: !_zoneAudioEnabled,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.redAccent.withOpacity(0.45),
                  inactiveThumbColor: Colors.white70,
                  inactiveTrackColor: Colors.white.withOpacity(0.12),
                  onChanged: (v) async {
                    final newEnabled = !v;
                    setState(() {
                      _zoneAudioEnabled = newEnabled;
                    });
                    await widget.onToggleMute(v);
                  },
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.06)),

                SwitchListTile(
                  title: const Text("Turn off vibration when my heart rate zone increases"),
                  value: !_zoneHapticEnabled,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.redAccent.withOpacity(0.45),
                  inactiveThumbColor: Colors.white70,
                  inactiveTrackColor: Colors.white.withOpacity(0.12),
                  onChanged: (v) async {
                    final newEnabled = !v;
                    setState(() {
                      _zoneHapticEnabled = newEnabled;
                    });
                    await widget.onToggleHaptics(v);
                  },
                ),

                Divider(height: 1, color: Colors.white.withOpacity(0.06)),

                ListTile(
                  title: const Text("Sound"),
                  subtitle: Text(widget.labelForAsset(_zoneAudioAsset)),
                  enabled: _zoneAudioEnabled,
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                  onTap: !_zoneAudioEnabled
                      ? null
                      : () async {
                    await showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) {
                        return SafeArea(
                          child: ListView(
                            children: widget.zoneSounds.entries.map((entry) {
                              final label = entry.key;
                              final asset = entry.value;
                              final selected = asset == _zoneAudioAsset;
                              final previewing = asset == _previewingAsset;

                              return ListTile(
                                title: Text(label),
                                leading: selected
                                    ? const Icon(Icons.check, color: Colors.white)
                                    : null,
                                trailing: IconButton(
                                  icon: Icon(
                                    previewing ? Icons.stop : Icons.play_arrow,
                                  ),
                                  onPressed: () async {
                                    if (previewing) {
                                      await widget.onStopPreview();
                                      if (mounted) {
                                        setState(() {
                                          _previewingAsset = null;
                                        });
                                      }
                                    } else {
                                      await widget.onPreviewSound(asset);
                                      if (mounted) {
                                        setState(() {
                                          _previewingAsset = asset;
                                        });
                                      }
                                    }
                                  },
                                ),
                                onTap: () async {
                                  setState(() {
                                    _zoneAudioAsset = asset;
                                    _previewingAsset = asset;
                                  });

                                  await widget.onSelectSound(asset);

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Preferences Settings
class PreferencesScreen extends StatefulWidget {
  final String? defaultWorkout;
  final List<String> activities;
  final Map<String, IconData> activityIcons;
  final Future<void> Function(String value) onWorkoutChanged;

  const PreferencesScreen({
    super.key,
    required this.defaultWorkout,
    required this.activities,
    required this.activityIcons,
    required this.onWorkoutChanged,
  });

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String? _currentWorkout;

  @override
  void initState() {
    super.initState();
    _currentWorkout = widget.defaultWorkout;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preferences")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionCard(
            child: ListTile(
              title: const Text("Default workout"),
              subtitle: Text(_currentWorkout ?? "Not set"),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: (_currentWorkout != null &&
                      widget.activities.contains(_currentWorkout))
                      ? _currentWorkout
                      : widget.activities.first,
                  items: widget.activities.map((a) {
                    return DropdownMenuItem(
                      value: a,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.activityIcons[a] ?? Icons.fitness_center),
                          const SizedBox(width: 8),
                          Text(a),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) async {
                    if (v == null) return;

                    setState(() {
                      _currentWorkout = v;
                    });

                    await widget.onWorkoutChanged(v);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}