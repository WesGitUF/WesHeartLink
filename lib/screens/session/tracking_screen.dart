import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:heart_link_app/models/heart_rate_zone.dart';
import 'package:heart_link_app/widgets/custom_widgets.dart'; // Contains PulseHeart & HeartRateMeter
import 'package:vibration/vibration.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});
  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  String? userDeviceId;
  String? partnerDeviceId;

  int _userHR = 0;
  int _partnerHR = 0;
  late int maxHeartRate;

  StreamSubscription<ConnectionStateUpdate>? _userConnection;
  StreamSubscription<ConnectionStateUpdate>? _partnerConnection;
  StreamSubscription<List<int>>? _userSubscription;
  StreamSubscription<List<int>>? _partnerSubscription;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  Duration _sameZoneDuration = Duration.zero;

  HeartRateZone? _previousUserZone;

  Future<void> _checkZoneTransition(int hr) async {
    final newZone = getZoneForHR(hr, maxHeartRate);
    if (_previousUserZone != null && newZone.name != _previousUserZone!.name) {
      final prevNum = int.tryParse(_previousUserZone!.name.split(' ').last) ?? 0;
      final newNum = int.tryParse(newZone.name.split(' ').last) ?? 0;
      if (newNum > prevNum) {
        Vibration.vibrate(duration: 3000, amplitude: 255);
      }
    }
    _previousUserZone = newZone;
  }

  // Flag to indicate that initialization is complete.
  bool _isInitialized = false;

  void _startTimer() {
    // print("Timer starting"); THAT WAS FOR TESTING: WESLY
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // print("Timer tick: ${_stopwatch.elapsed}"); THAT WAS FOR TESTING: WESLY
      setState(() {
        // Calculate zones for current HR values using maxHeartRate
          var currentUserZone = getZoneForHR(_userHR, maxHeartRate);
          var currentPartnerZone = getZoneForHR(_partnerHR, maxHeartRate);
          // If the zones are the same then add one second to _sameZoneDuration
          if (currentUserZone.name == currentPartnerZone.name) {
            _sameZoneDuration += const Duration(seconds: 1);
          }
      }); // Refresh the UI every second
    });
  }

  void _stopTimerAndNavigate() {
    _stopwatch.stop();
    _timer?.cancel();

    final elapsed = _stopwatch.elapsed;

    final List<int> series = [];

    final double avgHR = _userHR.toDouble();

    final String topZone = getZoneForHR(_userHR, maxHeartRate).name;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/trackingResult',
          (Route<dynamic> route) => false,
      arguments: {
        'elapsed': elapsed,
        'sameZone': _sameZoneDuration,

        // Required by route builder:
        'workoutMode': 'Workout',
        'workoutModeIcon': Icons.fitness_center,
        'maxHR': _userHR,
        'avgHR': avgHR,
        'series': series,
        'topZone': topZone,
        'theoreticalMaxHr': maxHeartRate,
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  void initState() {
    super.initState();
    print("TrackingScreen initState called");
    Future.delayed(Duration.zero, () {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      userDeviceId = args['userDeviceId'] as String?;
      partnerDeviceId = args['partnerDeviceId'] as String?;
      maxHeartRate = args['maxHR'] as int;
      print("TrackingScreen received: userDeviceId=$userDeviceId, partnerDeviceId=$partnerDeviceId, maxHR=$maxHeartRate");
      setState(() {
        _isInitialized = true;
      });
      _connectToDevices();
      _startTimer();
    });
  }

  void _connectToDevices() {
    if (userDeviceId != null) {
      _userConnection = _ble.connectToDevice(
        id: userDeviceId!,
        connectionTimeout: const Duration(seconds: 10),
      ).listen((connectionState) {
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          _subscribeToCharacteristic(userDeviceId!, isUser: true);
        }
      });
    }
    if (partnerDeviceId != null) {
      _partnerConnection = _ble.connectToDevice(
        id: partnerDeviceId!,
        connectionTimeout: const Duration(seconds: 10),
      ).listen((connectionState) {
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          _subscribeToCharacteristic(partnerDeviceId!, isUser: false);
        }
      });
    }
    // Once connections start, cancel scanning to reduce load.
    _scanSubscription?.cancel();
  }

  void _subscribeToCharacteristic(String deviceId, {required bool isUser}) {
    final characteristic = QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: Uuid.parse("180D"),
      characteristicId: Uuid.parse("2A37"),
    );

    final subscription = _ble.subscribeToCharacteristic(characteristic).listen(
      (data) {
        int hrValue = data.length > 1 ? data[1] : 0;
        if (isUser && _isInitialized) {
          _checkZoneTransition(hrValue);
        }
        setState(() {
          if (isUser) {
            _userHR = hrValue;
          } else {
            _partnerHR = hrValue;
          }
        });
      },
      onError: (error) {
        print("Error on device $deviceId: $error");
      },
    );

    if (isUser) {
      _userSubscription = subscription;
    } else {
      _partnerSubscription = subscription;
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _partnerSubscription?.cancel();
    _userConnection?.cancel();
    _partnerConnection?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wait for initialization before building UI that depends on maxHeartRate.
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tracking Heart Rates')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    HeartRateZone userZone = getZoneForHR(_userHR, maxHeartRate);
    HeartRateZone partnerZone = getZoneForHR(_partnerHR, maxHeartRate);
    bool sameZone = userZone.name == partnerZone.name;

    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Heart Rates')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Elapsed Time: ${_formatDuration(_stopwatch.elapsed)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Divider(thickness: 3, color: Colors.black),
            Expanded(
              child: Container(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PulseHeart(size: 150, color: Colors.red),
                          const SizedBox(height: 5),
                          const Text('You', style: TextStyle(fontSize: 25)),
                          Text('$_userHR bpm', style: const TextStyle(fontSize: 30)),
                          Text('Zone: ${userZone.name}', style: const TextStyle(fontSize: 25)),
                        ],
                      ),
                      const SizedBox(width: 20),
                      HeartRateMeter(heartRate: _userHR, maxHeartRate: maxHeartRate),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(thickness: 3, color: Colors.black),
            Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sameZone ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  sameZone
                      ? 'Great job! You’re both in the same zone ❤️'
                      : 'Alert: In different zones. Adjust your paces.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 25, color: Colors.black),
                ),
              ),
            ),
            const Divider(thickness: 3, color: Colors.black),
            Expanded(
              child: Container(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PulseHeart(size: 150, color: Colors.red),
                          const SizedBox(height: 5),
                          const Text('Partner:', style: TextStyle(fontSize: 25)),
                          Text('$_partnerHR bpm', style: const TextStyle(fontSize: 30)),
                          Text('Zone: ${partnerZone.name}', style: const TextStyle(fontSize: 25)),
                        ],
                      ),
                      const SizedBox(width: 20),
                      HeartRateMeter(heartRate: _partnerHR, maxHeartRate: maxHeartRate),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(thickness: 3, color: Colors.black),
            ElevatedButton(
              onPressed: () {
              _stopTimerAndNavigate();
              },
              style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              textStyle: const TextStyle(fontSize: 24),
              ),
              child: const Text("Stop Tracking"),
            ),
          ],
        ),
      ),
    );
  }
}
