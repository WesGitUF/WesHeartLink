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

  // debug sliders
  int _userSliderHR = 0;
  int _partnerSliderHR = 0;
  bool _userBleConnected = false;
  bool _partnerBleConnected = false;

  int get _effectiveUserHR => _userBleConnected ? _userHR : _userSliderHR;
  int get _effectivePartnerHR => _partnerBleConnected ? _partnerHR : _partnerSliderHR;

  StreamSubscription<ConnectionStateUpdate>? _userConnection;
  StreamSubscription<ConnectionStateUpdate>? _partnerConnection;
  StreamSubscription<List<int>>? _userSubscription;
  StreamSubscription<List<int>>? _partnerSubscription;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  Duration _sameZoneDuration = Duration.zero;
  final List<int> _series = [];

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

  bool _isInitialized = false;

  void _startTimer() {
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _series.add(_effectiveUserHR);
        var currentUserZone = getZoneForHR(_effectiveUserHR, maxHeartRate);
        var currentPartnerZone = getZoneForHR(_effectivePartnerHR, maxHeartRate);
        if (currentUserZone.name == currentPartnerZone.name) {
          _sameZoneDuration += const Duration(seconds: 1);
        }
      });
    });
  }

  void _stopTimerAndNavigate() {
    _stopwatch.stop();
    _timer?.cancel();

    final elapsed = _stopwatch.elapsed;
    final List<int> series = List<int>.from(_series);
    final double avgHR = series.isNotEmpty
        ? series.reduce((a, b) => a + b) / series.length
        : _effectiveUserHR.toDouble();
    final String topZone = getZoneForHR(_effectiveUserHR, maxHeartRate).name;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/trackingResult',
      (Route<dynamic> route) => false,
      arguments: {
        'elapsed': elapsed,
        'sameZone': _sameZoneDuration,
        'workoutMode': 'Workout',
        'workoutModeIcon': Icons.fitness_center,
        'maxHR': _effectiveUserHR,
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
    return '$hours:$minutes:$seconds';
  }

  @override
  void initState() {
    super.initState();
    print('TrackingScreen initState called');
    Future.delayed(Duration.zero, () {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      userDeviceId = args['userDeviceId'] as String?;
      partnerDeviceId = args['partnerDeviceId'] as String?;
      maxHeartRate = args['maxHR'] as int;
      print('TrackingScreen received: userDeviceId=$userDeviceId, partnerDeviceId=$partnerDeviceId, maxHR=$maxHeartRate');
      _userSliderHR = (maxHeartRate * 0.40).round();
      _partnerSliderHR = (maxHeartRate * 0.40).round();
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
          setState(() => _userBleConnected = true);
          _subscribeToCharacteristic(userDeviceId!, isUser: true);
        } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
          setState(() => _userBleConnected = false);
        }
      });
    }
    if (partnerDeviceId != null) {
      _partnerConnection = _ble.connectToDevice(
        id: partnerDeviceId!,
        connectionTimeout: const Duration(seconds: 10),
      ).listen((connectionState) {
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          setState(() => _partnerBleConnected = true);
          _subscribeToCharacteristic(partnerDeviceId!, isUser: false);
        } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
          setState(() => _partnerBleConnected = false);
        }
      });
    }
    _scanSubscription?.cancel();
  }

  void _subscribeToCharacteristic(String deviceId, {required bool isUser}) {
    final characteristic = QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: Uuid.parse('180D'),
      characteristicId: Uuid.parse('2A37'),
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
        print('Error on device $deviceId: $error');
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
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tracking Heart Rates')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    HeartRateZone userZone = getZoneForHR(_effectiveUserHR, maxHeartRate);
    HeartRateZone partnerZone = getZoneForHR(_effectivePartnerHR, maxHeartRate);
    bool sameZone = userZone.name == partnerZone.name;
    final int minBpm = (maxHeartRate * 0.40).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Heart Rates')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Elapsed Time: ${_formatDuration(_stopwatch.elapsed)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Divider(thickness: 3, color: Colors.black),
            SizedBox(
              height: 250,
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
                        Text('$_effectiveUserHR bpm', style: const TextStyle(fontSize: 30)),
                        Text('Zone: ${userZone.name}', style: const TextStyle(fontSize: 25)),
                      ],
                    ),
                    const SizedBox(width: 20),
                    HeartRateMeter(heartRate: _effectiveUserHR, maxHeartRate: maxHeartRate),
                  ],
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
                      ? 'Great job! You\'re both in the same zone!'
                      : 'Alert: In different zones. Adjust your paces.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 25, color: Colors.black),
                ),
              ),
            ),
            const Divider(thickness: 3, color: Colors.black),
            SizedBox(
              height: 250,
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
                        Text('$_effectivePartnerHR bpm', style: const TextStyle(fontSize: 30)),
                        Text('Zone: ${partnerZone.name}', style: const TextStyle(fontSize: 25)),
                      ],
                    ),
                    const SizedBox(width: 20),
                    HeartRateMeter(heartRate: _effectivePartnerHR, maxHeartRate: maxHeartRate),
                  ],
                ),
              ),
            ),
            const Divider(thickness: 3, color: Colors.black),
            // debug sliders
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'You BPM: $_effectiveUserHR',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: _userSliderHR.clamp(minBpm, maxHeartRate).toDouble(),
                  min: minBpm.toDouble(),
                  max: maxHeartRate.toDouble(),
                  divisions: maxHeartRate - minBpm,
                  label: '$_userSliderHR',
                  onChanged: _userBleConnected
                      ? null
                      : (v) => setState(() => _userSliderHR = v.round()),
                ),
                Text(
                  'Partner BPM: $_effectivePartnerHR',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: _partnerSliderHR.clamp(minBpm, maxHeartRate).toDouble(),
                  min: minBpm.toDouble(),
                  max: maxHeartRate.toDouble(),
                  divisions: maxHeartRate - minBpm,
                  label: '$_partnerSliderHR',
                  onChanged: _partnerBleConnected
                      ? null
                      : (v) => setState(() => _partnerSliderHR = v.round()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _stopTimerAndNavigate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                textStyle: const TextStyle(fontSize: 24),
              ),
              child: const Text('Stop Tracking'),
            ),
          ],
        ),
      ),
    );
  }
}
