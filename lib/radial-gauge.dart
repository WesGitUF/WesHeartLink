import 'package:flutter/material.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';
import 'package:heart_link_app/screens/session/tracking_result_screen.dart';
import 'package:heart_link_app/services/nearby_stream_service.dart';
import 'package:heart_link_app/services/session_service.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'dart:async';
import 'dart:math';
import 'package:heart_link_app/models/heart_rate_zone.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:heart_link_app/services/background_setup.dart';
import 'package:heart_link_app/services/workout_audio_settings.dart';
import 'package:heart_link_app/services/workout_notification_service.dart';
import 'package:heart_link_app/services/workout_haptic_settings.dart';
import 'package:heart_link_app/services/active_workout_store.dart';
import 'package:heart_link_app/services/bpm_log_file.dart';
import 'package:heart_link_app/services/workout_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GaugeChart extends StatefulWidget {
  final String userDeviceId;
  //final String partnerDeviceId;
  final bool isHost;
  final String workoutMode;
  final bool isOnline;

  const GaugeChart({
    Key? key,
    required this.userDeviceId,
    //required this.partnerDeviceId,
    required this.isOnline,
    required this.isHost,
    required this.workoutMode,
  }) : super(key: key);

  @override
  _GaugeChartState createState() => _GaugeChartState();
}

class _GaugeChartState extends State<GaugeChart> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final SessionService _sessionService = SessionService();

  final refHeight = 915; //reference height in px
  final refWidth = 412; //reference width in px

  double heightRatio = 1.0;
  double widthRatio = 1.0;

  //define bluetooth connections and packet listeners
  StreamSubscription<ConnectionStateUpdate>? _userConnection;
  StreamSubscription<List<int>>? _userSubscription;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;

  //store device ID
  String? userDeviceId;

  // background tracking
  bool _bgGateBypassed = false; // user explicitly chose "Continue anyway"
  bool _bgGateDialogOpen = false; // prevents dialog stacking
  bool _notifListenerBound = false;
  bool _attemptedBatteryFix = false;
  bool _attemptedNotifFix = false;

  // stop watch for session timer
  final _stopwatch = Stopwatch();

  //booleans to check state of session
  bool isLoading = true;
  bool _isPaused = true;
  bool done = false;
  bool isSolo = false;

  //define user max HR, as well as current user and partner HR values
  int? _maxHeartRate;
  int userAge = 0;
  double _userWeight = 70.0;
  String _userGender = '';
  int _userHR = 100;
  int _partnerHR = 0;
  int _sliderHR = 100;

  //passed from previous screen, if hosting/joining or using online/offline mode
  bool? _isHost;
  bool? _isOnline;
  bool _showOverlay = true;

  bool _guestConnected = false;
  bool _isActiveSession = true;

  bool _showPercent = false;

  //initialize user and partner HR zone, using heart rate zone clas
  late HeartRateZone userZone;
  late HeartRateZone partnerZone;

  //current workout message based on HR zone
  late String workoutMessage;
  final _random = Random();
  late final AudioPlayer _audioPlayer;

  Timer? _timer;

  StreamSubscription<Map<String, dynamic>?>? _sessionListener;

  // play animation controller
  late final AnimationController _pulseController;

  //keep track of if displayed emoji is user or partner
  bool userImage = true;
  late String currentImage;

  late String _workoutMode;
  IconData? _workoutModeIcon;

  // Helpers for monitoring user/partner HR zones
  Duration _sameZone = Duration.zero;
  int? _lastMsgIndex; // avoid repeating the same message consecutively

  Duration _elapsed = Duration.zero;

  // For HR tracking over session
  int _maxSessionHR = 0;
  int _hrSum = 0;
  int _hrCount = 0; // to calculate average efficiently

  // For crash-recovery auto-save
  DateTime? _workoutStartTime;
  int _ticksSinceLastSave = 0;
  int _lastSavedBpmIndex = 0; // tracks how many BPM entries have been flushed
  static const int _saveIntervalTicks = 10; // save every 10 s

  String? sessionId;
  final TextEditingController _sessionIdController = TextEditingController();

  // For zone tracking
  Map<String, int> zoneTime = {}; // time spent in each zone in milliseconds
  List<int> hrValues = []; // store HR values over time

  // for haptic zone feedback increments (prevents ding spam)
  DateTime? _lastZoneUpFeedbackAt;
  static const Duration _zoneUpCooldown = Duration(milliseconds: 1500);

  String get mostFrequentZone {
    if (zoneTime.isEmpty) return 'Unknown';
    return zoneTime.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  String get currentMaxZone => userZone.name;

  //getter for avg hr. hr sum is updated every second in _tickUpdate, as is hr count
  double get averageHR {
    if (_hrCount == 0) return 0;
    return _hrSum / _hrCount;
  }

  Future<bool> _ensureBackgroundSetupBeforeStart() async {
    if (kIsWeb) return true;
    if (_bgGateBypassed) return true;

    // Avoid stacking dialogs
    if (_bgGateDialogOpen) return false;

    _attemptedBatteryFix = false;
    _attemptedNotifFix = false;
    _bgGateDialogOpen = true;

    try {
      while (mounted) {
        final s = await BackgroundSetup.check();
        if (s.allOk) return true;

        final result = await showDialog<String>(
          context: context,
          barrierDismissible: false, // MUST answer before starting
          builder: (context) {
            final problems = <String>[];
            if (!s.batteryOk) problems.add(
                "Switch battery optimization to unrestricted");
            if (!s.notifOk) problems.add(
                "Allow workout in progress notifications");

            return AlertDialog(
              title: const Text("Enable background tracking"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Before starting, we recommend you:"),
                  const SizedBox(height: 10),
                  ...problems.map((p) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• "),
                            Expanded(child: Text(p)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 10),
                  const Text(
                    "This helps keep tracking running in the background.",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, "bypass"),
                  child: const Text("Continue anyway"),
                ),

                // Show battery button only if:
                // - battery still not ok
                // - AND user hasn't already attempted battery fix in this gating session
                if (!s.batteryOk && !_attemptedBatteryFix)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, "battery"),
                    child: const Text("Fix battery"),
                  ),

                // Show notif button only if:
                // - notifications still not ok
                // - AND user hasn't already attempted notif fix in this gating session
                if (!s.notifOk && !_attemptedNotifFix)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, "notif"),
                    child: const Text("Allow notifications"),
                  ),
              ],
            );
          },
        );

        if (result == "bypass") {
          _bgGateBypassed = true;
          return true;
        }

        if (result == "battery") {
          _attemptedBatteryFix = true;
          await BackgroundSetup.fixBattery();
          continue;
        }

        if (result == "notif") {
          _attemptedNotifFix = true;
          await BackgroundSetup.fixNotifications();
          await _onPermissionsPossiblyChanged();
          continue;
        }

        // If dialog closed oddly, do not start.
        return false;
      }

      return false;
    } finally {
      _bgGateDialogOpen = false;
    }
  }

  Future<void> _onPermissionsPossiblyChanged() async {
    if (kIsWeb) return;

    // Only care if workout is actually running (overlay dismissed and active session)
    final workoutRunning = _isActiveSession && !_showOverlay;

    if (!workoutRunning) return;

    final s = await BackgroundSetup.check();
    if (!mounted) return;

    // If notifications are now allowed, ensure the foreground notification is running NOW
    if (s.notifOk) {
      // A safe way: stop then start to force notification to appear immediately
      await WorkoutNotificationService.stop();
      await _startWorkoutNotification();
    }
  }

  void _markWorkoutActive() {
    // Clear any BPM data left over from a previous session so the new workout
    // starts with a clean file. _lastSavedBpmIndex is reset to 0 so appends
    // start from the beginning of the new hrValues list.
    _lastSavedBpmIndex = 0;
    BpmLogFile.clear(); // fire-and-forget
  }

  Future<void> _saveCurrentState() async {
    if (!_isActiveSession || _showOverlay || _workoutStartTime == null) return;
    // Append only the new BPM entries since the last save — O(new entries) not O(total)
    final newEntries = hrValues.sublist(_lastSavedBpmIndex);
    await BpmLogFile.append(newEntries);
    _lastSavedBpmIndex = hrValues.length;

    await ActiveWorkoutStore.save(
      active: true,
      start: _workoutStartTime!,
      elapsed: _stopwatch.elapsed,
      paused: _isPaused,
      maxHr: _maxSessionHR,
      sumHr: _hrSum,
      timesHr: _hrCount,
      workoutMode: _workoutMode,
      theoreticalMaxHr: _maxHeartRate ?? 0,
    );
  }


  Future<void> _stopWorkoutNotification() async {
    if (kIsWeb) return;
    await WorkoutNotificationService.stop();
  }

  void _showTrackingSummary(BuildContext context, {required double calories}) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TrackingResultScreen(
              elapsedTime: _elapsed,
              sameZoneTime: _sameZone,
              workoutMode: _workoutMode,
              workoutModeIcon: _workoutModeIcon!,
              maxHeartRate: _maxSessionHR,
              avgHeartRate: averageHR.toDouble(),
              calories: calories,
              series: hrValues,
              isSolo: isSolo,
              topZone: peakZoneName,
              theoreticalMaxHr: _maxHeartRate!,
            ),
      ),
          (_) => false,
    );
  }

  Future<void> _startWorkoutNotification() async {
    if (kIsWeb) return;

    if (!_notifListenerBound) {
      _notifListenerBound = true;
      WorkoutNotificationService.listenForActions(() async {
        if (!mounted) return;
        if (!_isActiveSession) return;
        await _endWorkout(context);
      });
    }

    await WorkoutNotificationService.start(
      title: "Workout in progress",
      text: "End workout to stop tracking",
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
        const Duration(milliseconds: 1000), (_) => _tickUpdate());
  }

  //update function to run every second during active session
  Future<void> _tickUpdate() async {
    if (!mounted) return;
    //return if paused, inactive, or no max HR set
    if (_isPaused) return;
    if (!_stopwatch.isRunning || !_isActiveSession) return;
    if (_maxHeartRate == null || _showOverlay) return;

    bool zoneBumpUp = false;

    setState(() {
      //check if using simulated HR (device ID is placeholder)
      //simulate HR changes if so
      if (userDeviceId == '00:11:22:33:44:55') {
        _userHR = _sliderHR;
      }

      _userHR = _userHR.clamp(0, _maxHeartRate!);

      // Determine current zones
      final prevZone = userZone;
      userZone = getZoneForHR(_userHR, _maxHeartRate!);
      if (_guestConnected) {
        partnerZone = getZoneForHR(_partnerHR, _maxHeartRate!);
        if (partnerZone == userZone) {
          _sameZone += Duration(milliseconds: 1000);
        }
      }
      if (prevZone != userZone) {
        updateImage();
        workoutMessage = _pickMessage(userZone);
        final prevNum = int.tryParse(prevZone.name
            .split(' ')
            .last) ?? 0;
        final newNum = int.tryParse(userZone.name
            .split(' ')
            .last) ?? 0;
        if (newNum > prevNum) {
          zoneBumpUp = true;
        }
      }

      // Send user HR to partner via Nearby or Firestore
      if (!_isOnline!) {
        nearbyService.sendHeartRate(_userHR);
      } else if (sessionId != null) {
        _sessionService.updateHeartRate(
          sessionId!,
          isHost: _isHost!,
          hr: _userHR,
        );
      }

      // Update session stats
      _hrSum += _userHR;
      _hrCount++;

      if (_userHR > _maxSessionHR) {
        _maxSessionHR = _userHR;
      }

      // Update time spent in current zone
      final zoneName = userZone.name;
      zoneTime[zoneName] = (zoneTime[zoneName] ?? 0) + 1000;
      hrValues.add(_userHR);

      _elapsed = _stopwatch.elapsed;
    });

    // Persist state periodically so a crash can be recovered on next launch
    _ticksSinceLastSave++;
    if (_ticksSinceLastSave >= _saveIntervalTicks) {
      _ticksSinceLastSave = 0;
      _saveCurrentState();
    }

    if (zoneBumpUp) {
      final now = DateTime.now();

      final canFire = _lastZoneUpFeedbackAt == null ||
          now.difference(_lastZoneUpFeedbackAt!) >= _zoneUpCooldown;

      if (canFire) {
        _lastZoneUpFeedbackAt = now;

        final audioEnabled = await WorkoutAudioSettings.isEnabled();
        final hapticEnabled = await WorkoutHapticSettings.isEnabled();
        if (!audioEnabled && !hapticEnabled) return;

        if (audioEnabled) {
          await _audioPlayer.setVolume(0);
          await _audioPlayer.resume();
          await Future.delayed(const Duration(milliseconds: 180));
        }

        if (hapticEnabled && (await Vibration.hasVibrator() ?? false)) {
          Vibration.vibrate(duration: 250, amplitude: 255);
        }

        if (audioEnabled) {
          await _audioPlayer.pause();
          await _audioPlayer.seek(Duration.zero);
          await _audioPlayer.setVolume(1.0);
          await _audioPlayer.resume();
        }
      }
    }
  }

  // use to get peak zone for workout max HR
  String get peakZoneName {
    if (_maxHeartRate == null) return 'Unknown';
    return getZoneForHR(_maxSessionHR, _maxHeartRate!).name;
  }

  // Listen for partner HR updates from Firestore in online mode
  void _listenForPartnerHR() {
    if (sessionId == null) return;

    _sessionListener =
        _sessionService.sessionStream(sessionId!).listen((data) async {
          if (data == null) return;

          // Update partner HR logic
          if (!_isHost! && data['user1HR'] != null) {
            setState(() => _partnerHR = data['user1HR']);
          } else if (_isHost! && data['user2HR'] != null) {
            setState(() => _partnerHR = data['user2HR']);
          }

          // End session check
          if (data['sessionActive'] == false) {
            await _stopWorkoutNotification();

            _timer?.cancel();
            _stopwatch.stop();
            _isActiveSession = false;

            await _sessionListener?.cancel();
            _sessionListener = null;

            final calories = WorkoutService.calculateCalories(
              avgHr: averageHR.toInt(),
              age: userAge,
              weight: _userWeight,
              gender: _userGender,
              duration: _elapsed,
            );

            if (mounted) {
              _showTrackingSummary(context, calories: calories.toDouble());
            }
          }
        });
  }

  // Update displayed emoji based on current zone
  // Also called when the user clicks on the emoji to change it to their partner's
  void updateImage() {
    userImage ? currentImage = userZone.emojiImg : currentImage =
        partnerZone.emojiImg;
  }

  void pickIcon() {
    // Assign workout icon in App Bar
    if (_workoutMode == "Running") {
      _workoutModeIcon = Icons.directions_run;
    }
    else if (_workoutMode == "Cycling") {
      _workoutModeIcon = Icons.directions_bike;
    }
    else if (_workoutMode == "HIIT") {
      _workoutModeIcon = Icons.fitness_center;
    }
    else if (_workoutMode == "Walking") {
      _workoutModeIcon = Icons.directions_walk;
    }
    else if (_workoutMode == "Swimming") {
      _workoutModeIcon = Icons.pool;
    }
  }

  String _pickMessage(HeartRateZone zone) {
    // Avoid repeating the same message twice in a row
    if (zone.messages.length <= 1) return zone.messages.first;

    var idx = _random.nextInt(zone.messages.length);
    if (_lastMsgIndex != null && idx == _lastMsgIndex) {
      idx = (idx + 1) % zone.messages.length;
    }
    _lastMsgIndex = idx;
    return zone.messages[idx];
  }

  Color _colorForZone(HeartRateZone zone) {
    final name = zone.name;
    if (name.contains('1')) return const Color(0xFF7D98AA);
    if (name.contains('2')) return const Color(0xFF3795E8);
    if (name.contains('3')) return const Color(0xFF52B84D);
    if (name.contains('4')) return const Color(0xFFFFA700);
    if (name.contains('5')) return const Color(0xFFFF5546);
    return const Color(0xFF8F939A);
  }

  Color _zoneColor() => _colorForZone(userZone);

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void _connectToDevices() {
    if (userDeviceId == '00:11:22:33:44:55') {
      return;
    }
    if (kIsWeb) {
      print("Bluetooth not supported on Web — skipping connect");
      return;
    }

    if (userDeviceId != null) {
      _userConnection = _ble.connectToDevice(
        id: userDeviceId!,
        connectionTimeout: const Duration(seconds: 10),
      ).listen((connectionState) {
        if (connectionState.connectionState ==
            DeviceConnectionState.connected) {
          _subscribeToCharacteristic(userDeviceId!);
        }
      });
    }
    // Once connections start, cancel scanning to reduce load.
    _scanSubscription?.cancel();
  }

  void _subscribeToCharacteristic(String deviceId) {
    final characteristic = QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: Uuid.parse("180D"),
      characteristicId: Uuid.parse("2A37"),
    );

    final subscription = _ble.subscribeToCharacteristic(characteristic).listen(
          (data) {
        setState(() {
          if (userDeviceId == '00:11:22:33:44:55') {
            return;
          }
          _userHR = _parseHeartRate(data);
        });
      },
      onError: (error) {
        print("Error on device $deviceId: $error");
      },
    );
    _userSubscription = subscription;
  }

  // Parse heart rate from characteristic data
  int _parseHeartRate(List<int> data) {
    if (data.isEmpty) return 0;

    final flags = data[0];
    final is16Bit = (flags & 0x01) != 0;

    if (is16Bit && data.length >= 3) {
      return (data[1] | (data[2] << 8));
    } else if (!is16Bit && data.length >= 2) {
      return data[1];
    }

    return 0;
  }


  Future<void> _setUserHR() async {
    final age = await _sessionService.fetchUserAge();
    if (age == 0) return;

    userAge = age;
    setState(() {
      _maxHeartRate = SessionService.computeMaxHr(userAge);
    });
  }

  // Initialize data before calling tickupdate
  Future<void> _initAsync() async {
    userAge = await _sessionService.fetchUserAge();
    _maxHeartRate = SessionService.computeMaxHr(userAge);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(
            currentUser.uid).get();
        final data = doc.data();
        if (data != null) {
          _userWeight = (data['weight'] != null) ? double.tryParse(
              data['weight'].toString()) ?? 70.0 : 70.0;
          _userGender = data['gender'] ?? '';
        }
      } catch (_) {}
    }

    userDeviceId = widget.userDeviceId;
    _workoutMode = widget.workoutMode;

    setState(() {
      // Calculate screen size ratios, based off of reference design size (412x915 emulator)
      double screenWidth = MediaQuery
          .of(context)
          .size
          .width;
      double screenHeight = MediaQuery
          .of(context)
          .size
          .height;

      widthRatio = screenWidth / refWidth;
      heightRatio = screenHeight / refHeight;
    });

    _isHost = widget.isHost;
    _isOnline = widget.isOnline;

    if (_isHost!) {
      createSession();
    }

    if (!_isOnline!) {
      bool permissionsGranted = await requestNearbyPermissions();

      if (!permissionsGranted) {
        print("Required permissions not granted for Nearby Connections.");
        return;
      }

      if (_isHost!) {
        await nearbyService.initializeNearby(
            role: "host",
            userName: FirebaseAuth.instance.currentUser?.displayName ?? "User",
            sessionCode: sessionId
        );
      }

      nearbyService.partnerHeartRate.addListener(() {
        final hr = nearbyService.partnerHeartRate.value;
        setState(() {
          _partnerHR = hr;
        });
      });

      nearbyService.guestConnectedNotifier.addListener(() async {
        final connected = nearbyService.guestConnectedNotifier.value;
        if (connected && !_guestConnected) {
          final ok = await _ensureBackgroundSetupBeforeStart();
          if (!ok) return;

          setState(() {
            _guestConnected = true;
            _showOverlay = false;
          });

          _markWorkoutActive();
          _stopwatch.start();
          _workoutStartTime = DateTime.now();
          _startTimer();
          await _startWorkoutNotification();
        }
      });
    }

    if (!_isOnline! && _isHost!) {
      setState(() {
        _showOverlay = false;
        isSolo = true;
      });
      _markWorkoutActive();
    }

    // Initialize data before calling tickupdate
    pickIcon();
    _setUserHR();

    _connectToDevices();

    userZone = getZoneForHR(_userHR, _maxHeartRate!);
    partnerZone = getZoneForHR(_partnerHR, _maxHeartRate!);
    updateImage();

    workoutMessage = _pickMessage(userZone);

    if (_isOnline!) _listenForGuestJoin();

    // Trigger rebuild
    setState(() {
      isLoading = false;
    });
  }

  Future<bool> requestNearbyPermissions() async {
    final location = await Permission.location.request();
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    final advertise = await Permission.bluetoothAdvertise.request();

    // Android 13+
    if (await Permission.nearbyWifiDevices.isDenied) {
      await Permission.nearbyWifiDevices.request();
    }

    final allGranted =
        location.isGranted &&
            scan.isGranted &&
            connect.isGranted &&
            advertise.isGranted;

    print("Permissions:");
    print("Location: $location");
    print("Scan: $scan");
    print("Connect: $connect");
    print("Advertise: $advertise");

    return allGranted;
  }


  Future<void> createSession() async {
    sessionId = _sessionService.generateSessionId();
    await _sessionService.createSession(sessionId!);
    _isActiveSession = true;
  }

  void _listenForGuestJoin() {
    if (!_isHost! || sessionId == null) return;

    _sessionService.sessionStream(sessionId!).listen((data) async {
      if (data != null && data['user2Id'] != null && !_guestConnected) {
        final ok = await _ensureBackgroundSetupBeforeStart();
        if (!ok) return;

        setState(() {
          _guestConnected = true;
          _showOverlay = false;
        });

        _listenForPartnerHR();
        _markWorkoutActive();
        _stopwatch.start();
        _workoutStartTime = DateTime.now();
        _startTimer();
        await _startWorkoutNotification();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _audioPlayer = AudioPlayer();

    _audioPlayer.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceNavigationGuidance,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );

    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.setVolume(1.0);

    WorkoutAudioSettings.getAsset().then((asset) {
      _audioPlayer.setSource(AssetSource(asset));
    });
    _initAsync();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userSubscription?.cancel();
    _userConnection?.cancel();
    _timer?.cancel();
    _audioPlayer.dispose();
    _sessionIdController.dispose();
    _sessionListener?.cancel();
    nearbyService.stopAll();

    WorkoutNotificationService.dispose();

    _pulseController.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      // If user just changed settings/permissions, react immediately
      await _onPermissionsPossiblyChanged();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // App is being backgrounded or killed — persist session immediately
      await _saveCurrentState();
    }
  }

  Widget _getGauge({bool isRadialGauge = true}) {
    return isRadialGauge ? _getRadialGauge() : _getLinearGauge();
  }

  GaugeAnnotation _rangeLabel({
    required String text,
    required double start,
    required double end,
    required double axisMin,
    required double axisMax,
    required double startAngle,
    required double endAngle,
    required Color color,
    double positionFactor = 0.92,
  }) {
    final mid = (start + end) / 2;
    final sweep = endAngle - startAngle;
    final t = (mid - axisMin) / (axisMax - axisMin);
    final angle = startAngle + t * sweep;

    return GaugeAnnotation(
      angle: angle,
      positionFactor: positionFactor,
      widget: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // confirmation popup to ensure users do not prematurely end workouts
  Future<void> _confirmEndWorkout(BuildContext context) async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("End Workout?"),
          content: const Text("Are you sure you want to end the workout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("End"),
            ),
          ],
        );
      },
    );

    if (shouldEnd == true) {
      await _endWorkout(context);
    }
  }

  Future<void> _endWorkout(BuildContext context) async {
    if (!_isActiveSession) return;
    await _stopWorkoutNotification();

    await ActiveWorkoutStore.clear();
    await BpmLogFile.clear();

    setState(() {
      _isActiveSession = false;
    });

    if (_isOnline! && sessionId != null) {
      _sessionService.endSession(sessionId!);
    }

    _timer?.cancel();
    _stopwatch.stop();

    if (!_guestConnected) {
      _sameZone = Duration.zero;
    }

    final calories = WorkoutService.calculateCalories(
      avgHr: averageHR.toInt(),
      age: userAge,
      weight: _userWeight,
      gender: _userGender,
      duration: _elapsed,
    );

    _showTrackingSummary(context, calories: calories.toDouble());
  }

  // Session overlay widget
  // Builds on top of gauge when workout is initialized/not yet started
  // Depending on if guest or host, generates session ID or prompts user to enter one
  Widget _buildSessionOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 40, 40, 41),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isHost!
                ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Share this Session ID:", style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent)),
                const SizedBox(height: 10),
                SelectableText(sessionId ?? "Loading...",
                    style: const TextStyle(
                        fontSize: 24, color: Colors.redAccent)),
                const SizedBox(height: 20),
                ValueListenableBuilder(
                    valueListenable: nearbyService.guestConnectedNotifier,
                    builder: (context, guestConnected, _) {
                      return ElevatedButton(
                        onPressed: (_isOnline! && !guestConnected)
                            ? null
                            : () async {
                          final ok = await _ensureBackgroundSetupBeforeStart();
                          if (!ok) return;

                          setState(() {
                            _showOverlay = false;

                            if (guestConnected) {
                              _guestConnected = true;
                            } else {
                              _guestConnected = false;
                              isSolo = true;
                            }
                          });

                          _markWorkoutActive();
                          _stopwatch.start();
                          _workoutStartTime = DateTime.now();
                          _startTimer();
                          await _startWorkoutNotification();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 20,
                              horizontal: 24),
                          textStyle: const TextStyle(fontSize: 24),
                        ),
                        child: Text(
                          guestConnected
                              ? 'Start Workout'
                              : (_isOnline!
                              ? 'Waiting for partner...'
                              : 'Start Solo Workout'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }
                )
              ],
            )
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Enter Session ID to Join:", style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent)),
                const SizedBox(height: 10),
                TextField(
                  controller: _sessionIdController,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                    hintText: "Enter code",
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: () async {
                      if (_sessionIdController.text.isEmpty) return;

                      sessionId = _sessionIdController.text.trim();


                      if (!_isOnline!) {
                        await nearbyService.initializeNearby(
                          role: "peer",
                          userName: FirebaseAuth.instance.currentUser
                              ?.displayName ?? "Guest",
                          sessionCode: sessionId,
                        );
                        return;
                      }

                      final result = await _sessionService.joinSession(
                          sessionId!);
                      if (result is String) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result)),
                          );
                        }
                        return;
                      }

                      final ok = await _ensureBackgroundSetupBeforeStart();
                      if (!ok) return;

                      setState(() {
                        _isHost = false;
                        _guestConnected = true;
                        _showOverlay = false;
                      });

                      _listenForPartnerHR();
                      _markWorkoutActive();
                      _stopwatch.start();
                      _workoutStartTime = DateTime.now();
                      _startTimer();
                      await _startWorkoutNotification();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 24),
                      textStyle: const TextStyle(fontSize: 24),
                    ),
                    child: Text(
                      'Join Session',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                      ),
                    )
                )
              ],
            ),
          ),
        ),
      ),
    );
  }


  // Radial gauge widget
  // Circular gauge with colored zones and pointers for user/partner HR
  Widget _getRadialGauge() {
    return SizedBox(
      width: 280,
      height: 280,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            radiusFactor: 1.05,
            minimum: _maxHeartRate! * 0.40,
            maximum: _maxHeartRate! * 1.10,
            startAngle: 30,
            endAngle: 390,
            showTicks: false,
            showLabels: false,
            axisLineStyle: const AxisLineStyle(
              thickness: 0,
            ),
            ranges: <GaugeRange>[
              GaugeRange(
                startValue: _maxHeartRate! * 0.40,
                endValue: _maxHeartRate! * 0.65,
                color: const Color(0xFF7D98AA),
                startWidth: 55,
                endWidth: 55,
              ),
              GaugeRange(
                startValue: _maxHeartRate! * 0.65,
                endValue: _maxHeartRate! * 0.80,
                color: const Color(0xFF3795E8),
                startWidth: 55,
                endWidth: 55,
              ),
              GaugeRange(
                startValue: _maxHeartRate! * 0.80,
                endValue: _maxHeartRate! * 0.89,
                color: const Color(0xFF52B84D),
                startWidth: 55,
                endWidth: 55,
              ),
              GaugeRange(
                startValue: _maxHeartRate! * 0.89,
                endValue: _maxHeartRate! * 0.95,
                color: const Color(0xFFFFA700),
                startWidth: 55,
                endWidth: 55,
              ),
              GaugeRange(
                startValue: _maxHeartRate! * 0.95,
                endValue: _maxHeartRate!.toDouble(),
                color: const Color(0xFFFF5546),
                startWidth: 55,
                endWidth: 55,
              ),
              GaugeRange(
                startValue: _maxHeartRate!.toDouble(),
                endValue: _maxHeartRate! * 1.10,
                color: const Color(0xFF1A1A1E),
                startWidth: 55,
                endWidth: 55,
              ),
            ],
            pointers: <GaugePointer>[
              MarkerPointer(
                value: _userHR.toDouble(),
                enableAnimation: true,
                animationDuration: 300,
                markerType: MarkerType.triangle,
                markerHeight: 38,
                markerWidth: 40,
                color: Colors.white,
                borderColor: _zoneColor(),
                borderWidth: 6.0,
                markerOffset: 60,
              ),
              if (_guestConnected) ...[
                MarkerPointer(
                  value: _partnerHR.toDouble(),
                  enableAnimation: true,
                  animationDuration: 300,
                  markerType: MarkerType.invertedTriangle,
                  markerHeight: 24,
                  markerWidth: 26,
                  color: Colors.white,
                  borderColor: _colorForZone(partnerZone),
                  borderWidth: 3.0,
                  markerOffset: -5,
                ),
                WidgetPointer(
                  value: _partnerHR.toDouble(),
                  enableAnimation: true,
                  animationDuration: 300,
                  offset: -38,
                  child: ClipOval(
                    child: Image.asset(
                      partnerZone.emojiImg,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ],
            annotations: <GaugeAnnotation>[
              // range labels for each zone
              _rangeLabel(
                  text: 'I',
                  start: _maxHeartRate! * 0.4,
                  end: _maxHeartRate! * 0.65,
                  axisMin: _maxHeartRate! * 0.4,
                  axisMax: _maxHeartRate! * 1.10,
                  startAngle: 30,
                  endAngle: 390,
                  positionFactor: 0.8,
                  color: Colors.blueGrey[800]!
              ),
              _rangeLabel(
                  text: 'II',
                  start: _maxHeartRate! * 0.65,
                  end: _maxHeartRate! * 0.8,
                  axisMin: _maxHeartRate! * 0.4,
                  axisMax: _maxHeartRate! * 1.10,
                  startAngle: 30,
                  endAngle: 390,
                  positionFactor: 0.8,
                  color: Colors.blue[800]!
              ),
              _rangeLabel(
                  text: 'III',
                  start: _maxHeartRate! * 0.8,
                  end: _maxHeartRate! * 0.89,
                  axisMin: _maxHeartRate! * 0.4,
                  axisMax: _maxHeartRate! * 1.10,
                  startAngle: 30,
                  endAngle: 390,
                  positionFactor: 0.8,
                  color: Colors.green[800]!
              ),
              _rangeLabel(
                  text: 'IV',
                  start: _maxHeartRate! * 0.89,
                  end: _maxHeartRate! * 0.95,
                  axisMin: _maxHeartRate! * 0.4,
                  axisMax: _maxHeartRate! * 1.10,
                  startAngle: 30,
                  endAngle: 390,
                  positionFactor: 0.8,
                  color: Colors.yellow[800]!
              ),
              _rangeLabel(
                  text: 'V',
                  start: _maxHeartRate! * 0.95,
                  end: _maxHeartRate!.toDouble(),
                  axisMin: _maxHeartRate! * 0.4,
                  axisMax: _maxHeartRate! * 1.10,
                  startAngle: 30,
                  endAngle: 390,
                  positionFactor: 0.8,
                  color: Colors.red[800]!
              ),
            ],
          ),
        ],
      ),
    );
  }

  // unused testing widget
  Widget _getLinearGauge() {
    return Container(
      margin: EdgeInsets.all(10),
      child: SfLinearGauge(
        minimum: 0.0,
        maximum: 100.0,
        orientation: LinearGaugeOrientation.horizontal,
        majorTickStyle: LinearTickStyle(length: 20),
        axisLabelStyle: TextStyle(fontSize: 12.0, color: Colors.black),
        axisTrackStyle: LinearAxisTrackStyle(
          color: Colors.cyan,
          edgeStyle: LinearEdgeStyle.bothFlat,
          thickness: 15.0,
          borderColor: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildWorkoutBody() {
    return SafeArea(
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 50),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),

                        Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showPercent = !_showPercent;
                              });
                            },
                            child: Text(
                              _showPercent && _maxHeartRate != null &&
                                  _maxHeartRate! > 0
                                  ? '${((_userHR / _maxHeartRate!) * 100)
                                  .round()}%'
                                  : '$_userHR BPM',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        SizedBox(
                          width: 340,
                          height: 340,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _getGauge(),
                              Container(
                                width: 115,
                                height: 115,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    userZone.emojiImg,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            workoutMessage.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              letterSpacing: 1.2,
                              color: _zoneColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 35),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.37,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF101113),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white24,
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Duration',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDuration(_elapsed),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.37,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF101113),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white24,
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Calories',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${WorkoutService.calculateCalories(
                                      avgHr: averageHR.toInt(),
                                      age: userAge,
                                      weight: _userWeight,
                                      gender: _userGender,
                                      duration: _elapsed,
                                    )} cal',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.37,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF101113),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _maxHeartRate != null &&
                                      _maxSessionHR > 0
                                      ? _colorForZone(getZoneForHR(
                                      _maxSessionHR, _maxHeartRate!))
                                      : Colors.white24,
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Max HR',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: (_maxHeartRate != null &&
                                          _maxSessionHR > 0
                                          ? _colorForZone(getZoneForHR(
                                          _maxSessionHR, _maxHeartRate!))
                                          : Colors.white)
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_maxSessionHR bpm',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _maxHeartRate != null &&
                                          _maxSessionHR > 0
                                          ? _colorForZone(getZoneForHR(
                                          _maxSessionHR, _maxHeartRate!))
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.37,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF101113),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _maxHeartRate != null && averageHR > 0
                                      ? _colorForZone(getZoneForHR(
                                      averageHR.round(), _maxHeartRate!))
                                      : Colors.white24,
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Avg HR',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: (_maxHeartRate != null &&
                                          averageHR > 0
                                          ? _colorForZone(getZoneForHR(
                                          averageHR.round(), _maxHeartRate!))
                                          : Colors.white)
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${averageHR.round()} bpm',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _maxHeartRate != null &&
                                          averageHR > 0
                                          ? _colorForZone(getZoneForHR(
                                          averageHR.round(), _maxHeartRate!))
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        if (_isPaused && _elapsed == Duration.zero)
                        // START BUTTON — matches session screen Continue button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: GestureDetector(
                              onTap: () async {
                                final ok = await _ensureBackgroundSetupBeforeStart();
                                if (!ok) return;
                                setState(() {
                                  _isPaused = false;
                                });
                                _pulseController.stop();
                                _workoutStartTime = DateTime.now();
                                _stopwatch.start();
                                _startTimer();
                                await _startWorkoutNotification();
                              },
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  final glowOpacity = 0.3 +
                                      (_pulseController.value * 0.3);
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.redStrong
                                              .withOpacity(glowOpacity),
                                          blurRadius: 24,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: child,
                                  );
                                },
                                child: Container(
                                  height: 56,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFFFF6467),
                                        AppColors.redStrong
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Start',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                        // PAUSE + STOP BUTTONS — shown after workout starts
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isPaused = !_isPaused;
                                    if (_isPaused) {
                                      _stopwatch.stop();
                                    } else {
                                      _stopwatch.start();
                                    }
                                  });
                                },
                                child: Container(
                                  width: 68,
                                  height: 68,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF101113),
                                  ),
                                  child: Icon(
                                    _isPaused ? Icons.play_arrow_rounded : Icons
                                        .pause_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 70),
                              GestureDetector(
                                onTap: () => _confirmEndWorkout(context),
                                child: Container(
                                  width: 68,
                                  height: 68,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF101113),
                                  ),
                                  child: const Icon(
                                    Icons.stop_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        if (userDeviceId == '00:11:22:33:44:55' &&
                            _maxHeartRate != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'BPM: $_sliderHR',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Slider(
                                  value: _sliderHR.clamp(
                                    (_maxHeartRate! * 0.40).round(),
                                    _maxHeartRate!,
                                  ).toDouble(),
                                  min: (_maxHeartRate! * 0.40).roundToDouble(),
                                  max: _maxHeartRate!.toDouble(),
                                  divisions: (_maxHeartRate! -
                                      (_maxHeartRate! * 0.40).round()),
                                  label: '$_sliderHR',
                                  onChanged: (v) =>
                                      setState(() => _sliderHR = v.round()),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (_showOverlay) _buildSessionOverlay(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || _maxHeartRate == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        color: AppColors.background,
        child: _buildWorkoutBody(),
      ),
    );
  }
}
