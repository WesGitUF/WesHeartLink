import 'package:flutter/material.dart';
import 'package:heart_link_app/screens/session/tracking_result_screen.dart';
import 'package:heart_link_app/services/nearby_stream_service.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'dart:async';
import 'dart:math';
import 'package:heart_link_app/models/heart_rate_zone.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

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

class _GaugeChartState extends State<GaugeChart> with WidgetsBindingObserver {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  final refHeight = 915; //reference height in px
  final refWidth = 412;  //reference width in px

  double heightRatio = 1.0;
  double widthRatio = 1.0;

  //define bluetooth connections and packet listeners
  StreamSubscription<ConnectionStateUpdate>? _userConnection;
  StreamSubscription<List<int>>? _userSubscription;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  //store device ID
  String? userDeviceId;


  // stop watch for session timer
  final _stopwatch = Stopwatch();

  //booleans to check state of session
  bool isLoading = true;
  bool _isPaused = false;
  bool done = false;
  bool isSolo = false;

  //define user max HR, as well as current user and partner HR values
  int? _maxHeartRate;
  int userAge = 0;
  int _userHR = 100;
  int _partnerHR = 0;

  //passed from previous screen, if hosting/joining or using online/offline mode
  bool? _isHost;
  bool? _isOnline;
  bool _showOverlay = true;

  bool _guestConnected = false;
  bool _isActiveSession = true;

  //initialize user and partner HR zone, using heart rate zone clas
  late HeartRateZone userZone;
  late HeartRateZone partnerZone;

  //current workout message based on HR zone
  late String workoutMessage;
  final _random = Random();

  Timer? _timer;

  StreamSubscription<DocumentSnapshot>? _sessionListener;

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
  int _hrCount = 0;  // to calculate average efficiently

  String? sessionId;
  final TextEditingController _sessionIdController = TextEditingController();

  // For zone tracking
  Map<String, int> zoneTime = {};   // time spent in each zone in milliseconds
  List<int> hrValues = [];      // store HR values over time

  String get mostFrequentZone {
    if (zoneTime.isEmpty) return 'Unknown';
    return zoneTime.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String get currentMaxZone => userZone.name;

  //getter for avg hr. hr sum is updated every second in _tickUpdate, as is hr count
  double get averageHR {
    if (_hrCount == 0) return 0;
    return _hrSum / _hrCount;
  }

  void _startTimer() {
    _timer?.cancel();
    Timer.periodic(const Duration(milliseconds: 1000), (_) => _tickUpdate());
  }

  //update function to run every second during active session
  void _tickUpdate() {
    //return if paused, inactive, or no max HR set
    if (_isPaused) return;
    if (!_stopwatch.isRunning || !_isActiveSession) return;
    if (_maxHeartRate == null || _showOverlay) return;
    setState(() {
      //check if using simulated HR (device ID is placeholder)
      //simulate HR changes if so
      if (userDeviceId == '00:11:22:33:44:55') {
        _userHR += ((_random.nextDouble() * 6) - 3).toInt();
      }

      _userHR = _userHR.clamp(0, _maxHeartRate!);

      // Determine current zones
      final prevZone = userZone;
      userZone = getZoneForHR(_userHR, _maxHeartRate!);
      if (_guestConnected) {
        partnerZone = getZoneForHR(_partnerHR, _maxHeartRate!);
        if (partnerZone == userZone) {_sameZone += Duration(milliseconds: 1000); }
      }
      if (prevZone != userZone) { 
        updateImage(); 
        workoutMessage = _pickMessage(userZone);
      }

      // Send user HR to partner via Nearby or Firestore
      if (!_isOnline!) {
        nearbyService.sendHeartRate(_userHR);
        print("Sent HR via Nearby: $_userHR");
      } else {
        // Write current user heart rate to Firestore
        if (sessionId != null) {
          FirebaseFirestore.instance.collection('sessions').doc(sessionId).update({
            _isHost! ? 'user1HR' : 'user2HR': _userHR,
          });
        } else {
          print("Session id is null");
        }
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
  }

  // Listen for partner HR updates from Firestore in online mode
  void _listenForPartnerHR() {
    if (sessionId == null) return;

    _sessionListener = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data == null) return;

      // Update partner HR logic
      if (!_isHost! && data['user1HR'] != null) {
        setState(() => _partnerHR = data['user1HR']);
      } else if (_isHost! && data['user2HR'] != null) {
        setState(() => _partnerHR = data['user2HR']);
      }

      // End session check
      if (data['sessionActive'] == false) {
        final averageHR = _hrCount > 0 ? _hrSum ~/ _hrCount : 0;
        _timer?.cancel();
        _stopwatch.stop();
        _isActiveSession = false;

        // Cancel listener before navigating
        await _sessionListener?.cancel();
        _sessionListener = null;

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => TrackingResultScreen(
              elapsedTime: _elapsed, 
              sameZoneTime: _sameZone, 
              workoutMode: _workoutMode, 
              workoutModeIcon: _workoutModeIcon!, 
              maxHeartRate: _maxSessionHR, 
              avgHeartRate: averageHR.toDouble(), 
              series: hrValues,
              topZone: mostFrequentZone)),
            (_) => false, 
          );
        }
      }
    });
  }

  // Update displayed emoji based on current zone
  // Also called when the user clicks on the emoji to change it to their partner's
  void updateImage() {
    userImage ? currentImage = userZone.emojiImg : currentImage = partnerZone.emojiImg;
  }

  void pickIcon() {
    // Assign workout icon in App Bar
    if (_workoutMode == "Running") { _workoutModeIcon = Icons.directions_run; }
    else if (_workoutMode == "Cycling") { _workoutModeIcon = Icons.directions_bike; }
    else if (_workoutMode == "HIIT") { _workoutModeIcon = Icons.fitness_center; }
    else if (_workoutMode == "Walking") { _workoutModeIcon = Icons.directions_walk; }
    else if (_workoutMode == "Swimming") { _workoutModeIcon = Icons.pool; }
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void _connectToDevices() {
    if (kIsWeb) {
      print("Bluetooth not supported on Web — skipping connect");
      return;
    }

    if (userDeviceId != null) {
      _userConnection = _ble.connectToDevice(
        id: userDeviceId!,
        connectionTimeout: const Duration(seconds: 10),
      ).listen((connectionState) {
        if (connectionState.connectionState == DeviceConnectionState.connected) {
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
          if (userDeviceId == '00:11:22:33:44:55') { return;}
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
    // Asynchronously get current user data from firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data == null || data['age'] == null) return;

    userAge = data['age'];

    setState(() {
      _maxHeartRate = (208 - (userAge * 0.7)).toInt();
    });
  }

  // Initialize data before calling tickupdate
  Future<void> _initAsync() async {
    // Get age from Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      userAge = doc.data()?['age'] ?? 0;
    }

    // Compute max HR
    _maxHeartRate = (208 - (userAge * 0.7)).toInt();

    userDeviceId = widget.userDeviceId;
    _workoutMode = widget.workoutMode;

    setState(() {
      // Calculate screen size ratios, based off of reference design size (412x915 emulator)
      double screenWidth = MediaQuery.of(context).size.width;
      double screenHeight = MediaQuery.of(context).size.height;

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

      await nearbyService.initializeNearby(
        role: _isHost! ? "host" : "peer",
        userName: FirebaseAuth.instance.currentUser?.displayName ?? "User",
        sessionCode: sessionId
      );

      // Keep partnerHR updated automatically
      nearbyService.partnerHeartRate.addListener(() {
        setState(() {
          _partnerHR = nearbyService.partnerHeartRate.value;
        });
      });
    }

    // Initialize data before calling tickupdate
    pickIcon();
    _setUserHR();

    _connectToDevices();

    userZone    = getZoneForHR(_userHR, _maxHeartRate!);
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Generate sessionId
    Random random = new Random();
    int rand = random.nextInt(1000);
    String sessionuid = randomLetters(3);
    sessionId = sessionuid+rand.toString();

    await FirebaseFirestore.instance.collection('sessions').doc(sessionId).set({
      'user1Id': user.uid,
      'user2Id': null,
      'user1HR': 0,
      'user2HR': 0,
      'startTime': FieldValue.serverTimestamp(),
      'sessionActive': true
    });

    _isActiveSession = true;

    print('Share this Session Code with partner: $sessionId');
  }

  void _listenForGuestJoin() {
    if (!_isHost! || sessionId == null) return;

    FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      if (data != null && data['user2Id'] != null && !_guestConnected) {
        setState(() {
          _guestConnected = true;
          _showOverlay = false;   
          _listenForPartnerHR();
          _stopwatch.start();     
          _startTimer();          
        });
      }
    });
  }

  // Helper for generating session code
  String randomLetters(int length) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final rand = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => letters.codeUnitAt(rand.nextInt(letters.length))),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initAsync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userSubscription?.cancel();
    _userConnection?.cancel();
    _timer?.cancel();
    _sessionIdController.dispose();
    _sessionListener?.cancel();
    nearbyService.stopAll();
    super.dispose();
  }

  Widget _getGauge({bool isRadialGauge = true}) {
    return isRadialGauge ? _getRadialGauge() : _getLinearGauge();
  }

  // Range label for radial gauge
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
      _endWorkout(context);
    }
  }

  void _endWorkout(BuildContext context ) {
    setState(() {
      _isActiveSession = false;
    });

    if (_isOnline! && sessionId != null) {
      FirebaseFirestore.instance.collection('sessions').doc(sessionId).update({
        'sessionActive': false,
      });
    }

    _timer?.cancel();
    _stopwatch.stop();

    if (!_guestConnected) {
      _sameZone = Duration.zero;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => TrackingResultScreen(
        elapsedTime: _elapsed, 
        sameZoneTime: _sameZone, 
        workoutMode: _workoutMode, 
        workoutModeIcon: _workoutModeIcon!, 
        maxHeartRate: _maxSessionHR, 
        avgHeartRate: averageHR.toDouble(), 
        series: hrValues, 
        topZone: mostFrequentZone)),
      (_) => false,
    );
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
                    const Text("Share this Session ID:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    const SizedBox(height: 10),
                    SelectableText(sessionId ?? "Loading...", style: const TextStyle(fontSize: 24, color: Colors.redAccent)),
                    const SizedBox(height: 20),
                    ValueListenableBuilder(
                      valueListenable: nearbyService.guestConnectedNotifier,
                      builder: (context, guestConnected, _) {
                        return ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showOverlay = false;

                              if (guestConnected) {
                                _guestConnected = true;      // paired workout
                              } else {
                                _guestConnected = false;  
                                isSolo = true;   // solo fallback
                              }
                            });

                            _stopwatch.start();
                            _startTimer();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                            textStyle: const TextStyle(fontSize: 24),
                          ),
                          child: Text(
                            guestConnected ? 'Start Workout' : 'Start Solo Workout',
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
                    const Text("Enter Session ID to Join:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
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
                        final user = FirebaseAuth.instance.currentUser;

                        if (!_isOnline!) {
                          await nearbyService.initializeNearby(
                            role: "peer",
                            userName: FirebaseAuth.instance.currentUser?.displayName ?? "Guest",
                            sessionCode: sessionId,
                          );

                          setState(() {
                            _isHost = false;
                            _guestConnected = true; // paired workout
                            _showOverlay = false;
                          });
                          _stopwatch.start(); 
                          _startTimer();
                          return;
                        }

                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please log in first.')),
                          );
                          return;
                        }

                        try {
                          final doc = await FirebaseFirestore.instance
                              .collection('sessions')
                              .doc(sessionId)
                              .get();

                          if (!doc.exists) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Session not found.')),
                            );
                            return;
                          }

                          final data = doc.data()!;
                          if (data['user2Id'] == null) {
                            // Assign this user as the partner (user2)
                            await doc.reference.update({'user2Id': user.uid});
                            setState(() {
                              _isHost = false;
                              _guestConnected = true; // paired workout
                              _showOverlay = false;  // Hide overlay after success
                            });
                            _listenForPartnerHR();
                            _stopwatch.start(); 
                            _startTimer();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Session is already full!')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned (
            //top: 120 * heightRatio,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  radiusFactor: 0.85,
                  minimum: _maxHeartRate! * 0.4,
                  maximum: _maxHeartRate!.toDouble(),
                  startAngle: 30,
                  endAngle: 330,
                  showTicks: false,
                  showLabels: false,
                  ranges: <GaugeRange>[
                    // start and end values for each zone
                    GaugeRange(
                        startValue: _maxHeartRate! * 0.4, endValue: _maxHeartRate! * 0.65, color: Colors.blueGrey, startWidth: 60, endWidth: 60),
                    GaugeRange(
                        startValue: _maxHeartRate! * 0.65, endValue: _maxHeartRate! * 0.8, color: Colors.blue, startWidth: 60, endWidth: 60),
                    GaugeRange(
                        startValue: _maxHeartRate! * 0.8, endValue: _maxHeartRate! * 0.89, color: Colors.green, startWidth: 60, endWidth: 60),
                    GaugeRange(
                        startValue: _maxHeartRate! * 0.89, endValue: _maxHeartRate! * 0.95, color: Colors.orange, startWidth: 60, endWidth: 60),
                    GaugeRange(
                        startValue: _maxHeartRate! * 0.95, endValue: _maxHeartRate!.toDouble(), color: Colors.red, startWidth: 60, endWidth: 60),
                  ],
                  pointers: <GaugePointer>[
                    // list of pointers - user and optional partner
                    // is a red upside-down triangle with an emoji at the end
                    MarkerPointer(
                      value: _userHR.toDouble(),
                      enableAnimation: true,
                      animationDuration: 300,
                      markerType: MarkerType.invertedTriangle, // upside-down triangle
                      markerHeight: 27,
                      markerWidth: 33,
                      color: Colors.red,
                      borderColor: Colors.black54,
                      borderWidth: 1.5,
                      // Place the triangle at the outer edge or slightly outside:
                      markerOffset: -6,
                    ),

                    // Emoji/image above the triangle, farther outside
                    WidgetPointer(
                      value: _userHR.toDouble(),
                      enableAnimation: true,
                      animationDuration: 300,
                      offset: -51,
                      child: ClipOval(
                        child: Image.asset(
                          userZone.emojiImg,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (_guestConnected) ...[
                      MarkerPointer(
                        value: _partnerHR.toDouble(),
                        enableAnimation: true,
                        animationDuration: 300,
                        markerType: MarkerType.invertedTriangle,
                        markerHeight: 18,
                        markerWidth: 22,
                        color: Colors.red,
                        borderColor: Colors.black54,
                        borderWidth: 1.5,
                        // Position of the triangle relative to gauge
                        markerOffset: -6,
                      ),
                      // Emoji or image above the triangle, farther outside
                      WidgetPointer(
                        value: _partnerHR.toDouble(),
                        enableAnimation: true,
                        animationDuration: 300,
                        offset: -34,
                        child: ClipOval(
                          child: Image.asset(
                            partnerZone.emojiImg,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ]
                  ],
                  annotations: <GaugeAnnotation>[
                    // range labels for each zone
                    _rangeLabel(
                      text: 'I',
                      start: _maxHeartRate! * 0.4,
                      end: _maxHeartRate! * 0.65,
                      axisMin: _maxHeartRate! * 0.4,
                      axisMax: _maxHeartRate!.toDouble(),
                      startAngle: 30,
                      endAngle: 330,
                      positionFactor: 0.8,
                      color: Colors.blueGrey[800]!
                    ),
                    _rangeLabel(
                      text: 'II',
                      start: _maxHeartRate! * 0.65,
                      end: _maxHeartRate! * 0.8,
                      axisMin:  _maxHeartRate! * 0.4,
                      axisMax: _maxHeartRate!.toDouble(),
                      startAngle: 30,
                      endAngle: 330,
                      positionFactor: 0.8,
                      color: Colors.blue[800]!
                    ),
                    _rangeLabel(
                      text: 'III',
                      start: _maxHeartRate! * 0.8,
                      end: _maxHeartRate! * 0.89,
                      axisMin:  _maxHeartRate! * 0.4, axisMax: _maxHeartRate!.toDouble(),
                      startAngle: 30, 
                      endAngle: 330, 
                      positionFactor: 0.8,
                      color: Colors.green[800]!
                    ),
                    _rangeLabel(
                      text: 'IV',
                      start: _maxHeartRate! * 0.89,
                      end: _maxHeartRate! * 0.95,
                      axisMin:  _maxHeartRate! * 0.4, axisMax: _maxHeartRate!.toDouble(),
                      startAngle: 30, 
                      endAngle: 330,
                      positionFactor: 0.8,
                      color: Colors.yellow[800]!
                    ),
                    _rangeLabel(
                      text: 'V',
                      start: _maxHeartRate! * 0.95,
                      end: _maxHeartRate!.toDouble(),
                      axisMin:  _maxHeartRate! * 0.4, axisMax: _maxHeartRate!.toDouble(),
                      startAngle: 30, 
                      endAngle: 330, 
                      positionFactor: 0.8,
                      color: Colors.red[800]!
                    ),
                  ],
                ),
              ],
            ),
          ),
          
        ],
      )
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

  @override
  Widget build(BuildContext context) {
    //draw circular loading widget if still loading
    if (isLoading || _maxHeartRate == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // App bar (heart logo w/ workout icon)
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
            title: Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(
                  _workoutModeIcon,
                  size: 50,
                  color: Colors.black
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              // ensure screen does not overflow when keyboard appears
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // HR DISPLAY
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 40, 40, 41),
                          border: Border.all(color: Colors.redAccent, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "$_userHR bpm",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // GAUGE
                    SizedBox(
                      width: MediaQuery.of(context).size.height * (2/5),
                      height: MediaQuery.of(context).size.height * (2/5),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _getGauge(),
                          GestureDetector(
                            onTap: () {
                              if (!_guestConnected) return;
                              userImage = !userImage;
                              updateImage();
                            },
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.transparent,
                              backgroundImage: AssetImage(currentImage),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 50),

                    // MESSAGE CARD
                    Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 40, 40, 41),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        workoutMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: userZone.colorValue.withOpacity(0.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // CONTROLS
                    Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 40, 40, 41),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatDuration(_elapsed),
                            style: TextStyle(
                              fontSize: 35 * heightRatio,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isPaused = !_isPaused;
                                    if (_isPaused) _stopwatch.stop();
                                    else _stopwatch.start();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 16),
                                ),
                                child: Text(
                                  _isPaused ? "Resume" : "Pause",
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),

                              const SizedBox(width: 20),

                              ElevatedButton(
                                onPressed: () => _confirmEndWorkout(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 16),
                                ),
                                child: const Text(
                                  "End",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),
            if (_showOverlay) _buildSessionOverlay(),
          ],
        ),
      ),
    );
  }
}